import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'storage_service.dart';
import 'models.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<ActivityLog> _logs = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  // ---------------- Load Real Logs ----------------
  Future<void> _loadLogs() async {
    setState(() => _isRefreshing = true);

    final logs = await StorageService.getLastLogs(200);

    setState(() {
      _logs = logs.reversed.toList();
      _isLoading = false;
      _isRefreshing = false;
    });
  }

  // ---------------- Load Sample Data ----------------
  Future<void> _loadSampleCSV() async {
    try {
      final csvString = await rootBundle.loadString("assets/sample_data.csv");

      final rows = const CsvToListConverter().convert(csvString);

      // Skip index 0 header row
      List<ActivityLog> sample = [];

      for (int i = 1; i < rows.length; i++) {
        final r = rows[i];

        final timestamp = DateTime.parse(r[0]);
        final placeName = r[1].toString(); // ignore "activity"
        // No Latitude/Longitude needed; your model stores placeName only

        sample.add(ActivityLog(
          timestamp: timestamp,
          activity: "unknown", // ignored anyway
          placeName: placeName,
        ));
      }

      setState(() {
        _logs = sample.reversed.toList();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sample data loaded!")),
      );
    } catch (e) {
      debugPrint("Sample CSV error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load sample data.")),
      );
    }
  }

  // ---------------- Export Logs ----------------
  Future<void> _exportLogsToCSV() async {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No logs to export.")),
      );
      return;
    }

    List<List<dynamic>> rows = [
      ["Timestamp", "PlaceName"]
    ];

    for (var log in _logs) {
      rows.add([
        DateFormat("yyyy-MM-dd HH:mm:ss").format(log.timestamp),
        log.placeName,
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);

    final directory = await getExternalStorageDirectory();
    final downloadsPath = directory!.path.replaceAll(
      "Android/data/${directory.uri.pathSegments[2]}/files",
      "Download",
    );

    final file = File("$downloadsPath/sample_data.csv");
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)], text: "Logs Export");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("CSV exported: ${file.path}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isRefreshing ? null : _loadLogs,
        icon: _isRefreshing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.refresh),
        label: Text(_isRefreshing ? "Refreshing…" : "Refresh Logs"),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top actions row
            Row(
              children: [
                IconButton(
                  onPressed: _exportLogsToCSV,
                  icon: const Icon(Icons.share_outlined),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _loadSampleCSV,
                  child: const Text("Use Sample Data"),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text("Logs", style: Theme.of(context).textTheme.displayLarge),

            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _logs.isEmpty
                      ? const Center(
                          child: Text(
                            "No logs available.",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return _TimelineItem(
                              log: _logs[index],
                              isFirst: index == 0,
                              isLast: index == _logs.length - 1,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// ---------------- Timeline Item ----------------
//
class _TimelineItem extends StatelessWidget {
  final ActivityLog log;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.log,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, yyyy').format(log.timestamp);
    final time = DateFormat('h:mm a').format(log.timestamp);

    return SizedBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT TIMELINE COLUMN
          Column(
            children: [
              // Top connector
              Container(
                width: 2,
                height: isFirst ? 16 : 28,
                color: isFirst ? Colors.transparent : Colors.grey.shade300,
              ),

              // Dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),

              // Bottom connector
              Container(
                width: 2,
                height: isLast ? 16 : 28,
                color: isLast ? Colors.transparent : Colors.grey.shade300,
              ),
            ],
          ),

          const SizedBox(width: 20),

          // RIGHT CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.placeName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$date — $time",
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.grey.shade700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
