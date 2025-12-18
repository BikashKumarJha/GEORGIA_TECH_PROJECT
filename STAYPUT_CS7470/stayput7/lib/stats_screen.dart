// stats_screen.dart — Modern Material You (Pixel T1 Tonal)
// FULLY UPDATED with:
// - Clean L1 layout
// - SegmentedButton (M3)
// - "Use Sample Summary"
// - Sample-mode flag (_usingSample)
// - Prevents real data from overwriting sample
// - Updated bar chart helper
// - Pixel card design (surfaceContainerLow)

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';
import 'storage_service.dart';
import 'activity_timeline_chart.dart';

enum TimePeriod { today, week }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  TimePeriod _selectedPeriod = TimePeriod.week;

  Map<String, double> _currentSummary = {};
  Map<String, double> _previousSummary = {};
  Map<String, double> _dailyHours = {};
  Map<String, double> _todayPlaceHours = {};
  List<ActivityLog> _todayLogs = [];

  double _currentTotalHours = 0.0;
  String _avgTimeInsight = '';
  String _mostFrequentPlace = 'N/A';

  final List<Color> _chartColors = [
    Colors.teal,
    Colors.tealAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
  ];

  final List<String> _daysOfWeek = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  bool _isLoading = true;
  bool _usingSample = false; // <–––– SAMPLE MODE FLAG

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
  }

  // ——————————————————————————————————————————
  // SAMPLE SUMMARY LOADER (Updated with _usingSample)
  // ——————————————————————————————————————————
  Future<void> _loadSampleSummaryFromCSV() async {
    try {
      final csvString = await rootBundle.loadString("assets/sample_data.csv");
      final rows = const CsvToListConverter().convert(csvString);

      List<ActivityLog> logs = [];
      for (int i = 1; i < rows.length; i++) {
        logs.add(ActivityLog(
          timestamp: DateTime.parse(rows[i][0]),
          activity: "unknown",
          placeName: rows[i][1].toString(),
        ));
      }

      logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      Map<String, double> totals = {};
      Map<String, double> dailyTotals = {};
      List<ActivityLog> todayTimeline = [];

      for (int i = 0; i < logs.length; i++) {
        final curr = logs[i];
        final next = i < logs.length - 1 ? logs[i + 1] : null;

        Duration diff = next != null
            ? next.timestamp.difference(curr.timestamp)
            : const Duration(minutes: 15);

        double hrs = diff.inMinutes / 60.0;

        totals[curr.placeName] = (totals[curr.placeName] ?? 0.0) + hrs;

        String dow = DateFormat('E').format(curr.timestamp);
        dailyTotals[dow] = (dailyTotals[dow] ?? 0.0) + hrs;

        String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
        if (DateFormat('yyyy-MM-dd').format(curr.timestamp) == todayKey) {
          todayTimeline.add(curr);
        }
      }

      setState(() {
        _usingSample = true; // <––– ENTER SAMPLE MODE
        _selectedPeriod = TimePeriod.week;

        _currentSummary = totals;
        _previousSummary = {};
        _dailyHours = dailyTotals;
        _todayPlaceHours = {};
        _todayLogs = todayTimeline;

        _currentTotalHours = totals.values.fold(0.0, (p, e) => p + e);
        _mostFrequentPlace =
            totals.entries.reduce((a, b) => a.value > b.value ? a : b).key;

        _avgTimeInsight = "Showing summary from sample data.";
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sample summary loaded!")));
    } catch (e) {
      debugPrint("Sample summary error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load sample summary.")));
    }
  }

  // ——————————————————————————————————————————
  // PROTECT REAL SUMMARY FROM OVERWRITING SAMPLE
  // ——————————————————————————————————————————
  Future<void> _loadSummaryData() async {
    if (_usingSample) return; // <–––– DO NOT LOAD REAL DATA IN SAMPLE MODE

    setState(() => _isLoading = true);

    DateTime now = DateTime.now();
    DateTime currentStart, currentEnd, prevStart, prevEnd;

    if (_selectedPeriod == TimePeriod.today) {
      currentStart = DateTime(now.year, now.month, now.day);
      currentEnd = now;

      prevStart = currentStart.subtract(const Duration(days: 1));
      prevEnd = currentStart.subtract(const Duration(milliseconds: 1));
    } else {
      currentStart = now.subtract(const Duration(days: 7));
      currentEnd = now;

      prevStart = now.subtract(const Duration(days: 14));
      prevEnd = now.subtract(const Duration(days: 7));
    }

    final currentRaw = await _aggregateSummary(currentStart, currentEnd);
    final previousRaw = await _aggregateSummary(prevStart, prevEnd);

    _dailyHours = await _calculateDailyHours();

    if (_selectedPeriod == TimePeriod.today) {
      _todayPlaceHours = await _calculateTodayPlaceHours();
      _todayLogs = await _fetchTodayLogs();
    } else {
      _todayPlaceHours = {};
      _todayLogs = [];
    }

    _currentTotalHours = currentRaw.values.fold(0.0, (a, b) => a + b);

    var sorted = currentRaw.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _currentSummary = Map.fromEntries(sorted.take(5));
    _previousSummary = previousRaw;

    _calculateInsights(currentRaw, currentStart, currentEnd);

    setState(() => _isLoading = false);
  }

  // ——————————————————————————————————————————
  // ORIGINAL DATA HELPERS (unchanged logic)
  // ——————————————————————————————————————————
  Future<List<ActivityLog>> _fetchTodayLogs() async {
    DateTime today = DateTime.now();
    return StorageService.getLogsForDate(today);
  }

  Future<Map<String, double>> _aggregateSummary(
      DateTime start, DateTime end) async {
    Map<String, double> agg = {};
    List<DailySummary> all = await StorageService.getAllDailySummaries();

    DateTime endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    for (var s in all) {
      DateTime d;
      try {
        d = DateFormat('yyyy-MM-dd').parse(s.date);
      } catch (_) {
        continue;
      }

      if ((d.isAfter(start) || d.isAtSameMomentAs(start)) &&
          (d.isBefore(endDay) || d.isAtSameMomentAs(endDay))) {
        s.placeDurations.forEach((p, h) {
          agg[p] = (agg[p] ?? 0.0) + h;
        });
      }
    }

    return agg;
  }

  Future<Map<String, double>> _calculateDailyHours() async {
    Map<String, double> totals = {};
    List<DailySummary> all = await StorageService.getAllDailySummaries();

    for (int i = 0; i < 7; i++) {
      totals[_daysOfWeek[
          (DateTime.now().subtract(Duration(days: i))).weekday - 1]] = 0.0;
    }

    for (var s in all) {
      DateTime d;
      try {
        d = DateFormat('yyyy-MM-dd').parse(s.date);
      } catch (_) {
        continue;
      }

      DateTime cutoff = DateTime.now().subtract(const Duration(days: 7));
      if (d.isAfter(cutoff) || d.isAtSameMomentAs(cutoff)) {
        String dow = _daysOfWeek[d.weekday - 1];
        totals[dow] = s.placeDurations.values.fold(0.0, (p, h) => p + h);
      }
    }

    return {
      for (var d in _daysOfWeek) d: totals[d] ?? 0.0,
    };
  }

  Future<Map<String, double>> _calculateTodayPlaceHours() async {
    Map<String, double> totals = {};
    List<DailySummary> all = await StorageService.getAllDailySummaries();

    String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (var s in all) {
      if (s.date == todayKey) {
        s.placeDurations.forEach((p, h) {
          totals[p] = (totals[p] ?? 0.0) + h;
        });
      }
    }
    return totals;
  }

  void _calculateInsights(
      Map<String, double> raw, DateTime start, DateTime end) {
    if (_currentTotalHours == 0) {
      _avgTimeInsight = "N/A";
      _mostFrequentPlace = "N/A";
      return;
    }

    var most = raw.entries.reduce((a, b) => a.value > b.value ? a : b);

    _mostFrequentPlace = most.key;

    int days = max(1, end.difference(start).inDays);
    double avg = most.value / days;

    _avgTimeInsight =
        "You spent an average of ${avg.toStringAsFixed(1)} hours/day at $_mostFrequentPlace.";

    double other = raw["Other"] ?? 0.0;
    double pct = (other / _currentTotalHours) * 100;

    if (pct >= 20) {
      _avgTimeInsight +=
          " The 'Other' category is significant (${pct.toStringAsFixed(0)}%).";
    }
  }

  // ——————————————————————————————————————————
  // PIE CHART
  // ——————————————————————————————————————————
  List<PieChartSectionData> _getPieSections() {
    if (_currentTotalHours == 0) return [];

    return _currentSummary.entries.toList().asMap().entries.map((entry) {
      int i = entry.key;
      double hrs = entry.value.value;
      double pct = (hrs / _currentTotalHours) * 100;

      return PieChartSectionData(
        color: _chartColors[i % _chartColors.length],
        value: pct,
        title: "${pct.round()}%",
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  // ——————————————————————————————————————————
  // WEEKLY BAR CHART
  // ——————————————————————————————————————————
  List<BarChartGroupData> _getBarGroups() {
    return _dailyHours.entries.toList().asMap().entries.map((entry) {
      int index = entry.key;
      double hours = entry.value.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: hours,
            color: Colors.teal,
            width: 12,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  // ——————————————————————————————————————————
  // CARD WRAPPER
  // ——————————————————————————————————————————
  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  // ——————————————————————————————————————————
  // UI
  // ——————————————————————————————————————————
  @override
  Widget build(BuildContext context) {
    String title = _selectedPeriod == TimePeriod.today
        ? "Today's Summary"
        : "This Week's Summary";

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // SAMPLE SUMMARY BUTTON
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonal(
                        onPressed: _loadSampleSummaryFromCSV,
                        child: const Text("Use Sample Summary"),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // PERIOD SELECTOR
                    SegmentedButton<TimePeriod>(
                      segments: const [
                        ButtonSegment(
                            value: TimePeriod.today, label: Text("Today")),
                        ButtonSegment(
                            value: TimePeriod.week, label: Text("This Week")),
                      ],
                      selected: {_selectedPeriod},
                      onSelectionChanged: (value) {
                        setState(() => _selectedPeriod = value.first);
                        if (!_usingSample) _loadSummaryData();
                      },
                    ),
                    const SizedBox(height: 24),

                    // PIE CHART
                    _card(
                      Column(
                        children: [
                          const Text(
                            "Time Spent Distribution",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections: _getPieSections(),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 0,
                                centerSpaceRadius: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // LOCATION BREAKDOWN TABLE
                    _card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Location Breakdown",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ..._currentSummary.entries
                              .toList()
                              .asMap()
                              .entries
                              .map(
                            (e) {
                              int i = e.key;
                              String place = e.value.key;
                              double hrs = e.value.value;
                              double pct = (hrs / _currentTotalHours) * 100;

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _chartColors[
                                            i % _chartColors.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        place,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Text(
                                      '${hrs.toStringAsFixed(1)}h',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${pct.toStringAsFixed(0)}%'),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // TOTAL HOURS
                    _card(
                      Text(
                        "Total Tracked Time: ${_currentTotalHours.toStringAsFixed(1)} hours",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),

                    // TREND CHART
                    _card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPeriod == TimePeriod.today
                                ? "Activity Timeline"
                                : "Daily Trend",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          // TODAY TIMELINE
                          if (_selectedPeriod == TimePeriod.today)
                            SizedBox(
                              height: 600,
                              child: ActivityTimelineChart(
                                logs: _todayLogs,
                                chartColors: _chartColors,
                              ),
                            )

                          // WEEKLY BAR CHART
                          else
                            SizedBox(
                              height: 200,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  barGroups: _getBarGroups(),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, _) {
                                          return Text(
                                            _daysOfWeek[value.toInt()],
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                      ),
                                    ),
                                    rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                  ),
                                  gridData: FlGridData(show: true),
                                  borderData: FlBorderData(show: false),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // INSIGHTS
                    _card(
                      Text(
                        _avgTimeInsight,
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
      ),
    );
  }
}
