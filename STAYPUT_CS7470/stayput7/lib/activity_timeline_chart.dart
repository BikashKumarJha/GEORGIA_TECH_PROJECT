// activity_timeline_chart.dart (Overflow-Safe Updated Version)

import 'package:flutter/material.dart';
import 'package:stayput7/models.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class ActivityTimelineChart extends StatelessWidget {
  final List<ActivityLog> logs;
  final List<Color> chartColors;
  final Map<String, int> placeColorIndex;

  ActivityTimelineChart({
    super.key,
    required this.logs,
    required this.chartColors,
  }) : placeColorIndex = _generatePlaceColorIndex(logs, chartColors);

  // Assign consistent colors for places
  static Map<String, int> _generatePlaceColorIndex(
      List<ActivityLog> logs, List<Color> chartColors) {
    Set<String> unique = logs.map((e) => e.placeName).toSet();
    Map<String, int> map = {};
    int index = 0;
    for (var place in unique) {
      map[place] = index % chartColors.length;
      index++;
    }
    return map;
  }

  // Timeline segment calculation logic
  List<Map<String, dynamic>> _calculateTimelineSegments() {
    if (logs.isEmpty) return [];

    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    List<Map<String, dynamic>> segments = [];

    const double totalDaySeconds = 24 * 60 * 60;

    for (int i = 0; i < logs.length; i++) {
      final current = logs[i];
      final next = (i + 1 < logs.length) ? logs[i + 1] : null;

      DateTime segmentStart = current.timestamp;
      DateTime segmentEnd = next?.timestamp ?? now;

      // Clamp segment bounds
      if (segmentStart.isBefore(startOfDay)) segmentStart = startOfDay;
      if (segmentEnd.isAfter(endOfDay)) segmentEnd = endOfDay;
      if (next == null && segmentEnd.isAfter(now)) segmentEnd = now;

      if (segmentEnd.isAfter(segmentStart) && segmentStart.day == now.day) {
        double startS =
            segmentStart.difference(startOfDay).inSeconds.toDouble();
        double endS = segmentEnd.difference(startOfDay).inSeconds.toDouble();

        segments.add({
          'place': current.placeName,
          'start': segmentStart,
          'end': segmentEnd,
          'startPercentage': startS / totalDaySeconds,
          'endPercentage': endS / totalDaySeconds,
          'durationMinutes': (endS - startS) / 60.0,
          'colorIndex': placeColorIndex[current.placeName] ?? 0,
        });
      }
    }
    return segments;
  }

  // Debug table (scroll-safe)
  Widget _buildDebugTable(
      List<ActivityLog> rawLogs, List<Map<String, dynamic>> segments) {
    final DateFormat fmt = DateFormat('HH:mm:ss');

    return Padding(
      padding: const EdgeInsets.only(top: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Raw Logs Input (Today)',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 8),

          // Raw logs
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: rawLogs.isEmpty
                ? const Text('No logs retrieved for today.')
                : Column(
                    children: rawLogs
                        .map((log) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                '${fmt.format(log.timestamp)} - ${log.placeName}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ))
                        .toList(),
                  ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Calculated Segments (For Chart)',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 10,
                dataRowMinHeight: 20,
                dataRowMaxHeight: 30,
                headingRowHeight: 30,
                columns: const [
                  DataColumn(
                      label: Text('Location',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Start',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('End',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('% Start',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold))),
                ],
                rows: segments.isEmpty
                    ? const [
                        DataRow(cells: [
                          DataCell(Text('No segments calculated.',
                              style: TextStyle(fontSize: 12))),
                          DataCell(Text('')),
                          DataCell(Text('')),
                          DataCell(Text('')),
                        ])
                      ]
                    : segments
                        .map(
                          (s) => DataRow(
                            cells: [
                              DataCell(Text(s['place'],
                                  style: const TextStyle(fontSize: 12))),
                              DataCell(Text(fmt.format(s['start']),
                                  style: const TextStyle(fontSize: 12))),
                              DataCell(Text(fmt.format(s['end']),
                                  style: const TextStyle(fontSize: 12))),
                              DataCell(Text(
                                  s['startPercentage'].toStringAsFixed(3))),
                            ],
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final segments = _calculateTimelineSegments();
    final sortedPlaces = placeColorIndex.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    const hourMarks = [0, 6, 12, 18, 24];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TIMELINE BAR
          Container(
            width: double.infinity,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(5),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;

                return Stack(
                  children: segments.map((segment) {
                    final startX = segment['startPercentage'] * totalWidth;
                    final endX = segment['endPercentage'] * totalWidth;
                    final width = endX - startX;

                    if (width < 1) return const SizedBox.shrink();

                    return Positioned(
                      left: startX,
                      top: 0,
                      bottom: 0,
                      width: width,
                      child: Tooltip(
                        message:
                            '${segment['place']} (${segment['durationMinutes'].toStringAsFixed(0)}m)',
                        child: Container(
                          decoration: BoxDecoration(
                            color: chartColors[segment['colorIndex']],
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(
                                  segment['startPercentage'] < 0.001 ? 5 : 0),
                              right: Radius.circular(
                                  segment['endPercentage'] > 0.999 ? 5 : 0),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // TIME LABELS
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: hourMarks
                  .map((h) => Text('${h}h',
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade600)))
                  .toList(),
            ),
          ),

          const SizedBox(height: 20),

          // LEGEND
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: sortedPlaces.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: chartColors[entry.value],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(entry.key, style: const TextStyle(fontSize: 12)),
                ],
              );
            }).toList(),
          ),

          // DEBUG TABLE
          _buildDebugTable(logs, segments),
        ],
      ),
    );
  }
}
