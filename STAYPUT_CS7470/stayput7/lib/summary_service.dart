// summary_service.dart
import 'package:intl/intl.dart';
import 'storage_service.dart';
import 'models.dart';

class SummaryService {
  /// Generate daily summary for a specific date
  static Future<DailySummary> buildDailySummary(DateTime date) async {
    List<ActivityLog> logs = await StorageService.getLogsForDate(date);

    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    Map<String, Duration> placeDurations = {};
    for (int i = 0; i < logs.length - 1; i++) {
      final current = logs[i];
      final next = logs[i + 1];
      final diff = next.timestamp.difference(current.timestamp);
      placeDurations[current.placeName] =
          (placeDurations[current.placeName] ?? Duration.zero) + diff;
    }

    // If only one log exists, assign a small default duration
    if (logs.length == 1) {
      final single = logs.first;
      placeDurations[single.placeName] =
          (placeDurations[single.placeName] ?? Duration.zero) +
              const Duration(minutes: 30);
    }

    return DailySummary(
      date: DateFormat('yyyy-MM-dd').format(date),
      placeDurations:
          placeDurations.map((k, v) => MapEntry(k, v.inMinutes / 60)),
    );
  }

  /// Run on app launch to compute missing summaries
  static Future<void> runDailySummary() async {
    List<ActivityLog> allLogs = await StorageService.getAllLogs();
    if (allLogs.isEmpty) return;

    // Determine range of dates
    allLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    DateTime firstDate = DateTime(allLogs.first.timestamp.year,
        allLogs.first.timestamp.month, allLogs.first.timestamp.day);
    DateTime lastDate =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (DateTime date = firstDate;
        date.isBefore(lastDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      DailySummary summary = await buildDailySummary(date);
      await StorageService.saveDailySummary(summary);
    }
  }
}
