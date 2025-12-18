import 'package:hive/hive.dart';
import 'models.dart';

class StorageService {
  static const String placesBoxName = 'places_box';
  static const String logsBoxName = 'logs_box';
  static const String summaryBoxName = 'summary_box';

  // Save Places
  static Future<void> savePlaces(List<Place> places) async {
    var box = await Hive.openBox(placesBoxName);
    List<Map<String, dynamic>> maps = places.map((p) => p.toMap()).toList();
    await box.put('places', maps);
  }

  static Future<List<Place>> getPlaces() async {
    var box = await Hive.openBox(placesBoxName);
    List<dynamic>? maps = box.get('places');

    // If empty, load defaults
    if (maps == null || maps.isEmpty) {
      List<Place> defaults = [
        Place(
          name: 'Home',
          latitude: 40.13834694214356,
          longitude: -83.01229173245268,
        ),
        Place(
          name: 'My Office',
          latitude: 40.14002607270086,
          longitude: -82.99824251306906,
        ),
      ];
      await savePlaces(defaults);
      return defaults;
    }

    return maps
        .map((m) => Place.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  // Save Logs
  static Future<void> saveLog(ActivityLog log) async {
    var box = await Hive.openBox(logsBoxName);
    List<dynamic> logs = box.get('logs', defaultValue: []);
    logs.add(log.toMap());
    await box.put('logs', logs);
  }

  static Future<List<ActivityLog>> getLogs() async {
    var box = await Hive.openBox(logsBoxName);
    List<dynamic>? maps = box.get('logs', defaultValue: []);
    if (maps != null) {
      return maps
          .map((m) => ActivityLog.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }
    return [];
  }

  // NEW: getLastLogs
  static Future<List<ActivityLog>> getLastLogs(int count) async {
    List<ActivityLog> logs = await getLogs();
    if (logs.length <= count) return logs;
    return logs.sublist(logs.length - count);
  }

  // NEW: getLogsForDate
  static Future<List<ActivityLog>> getLogsForDate(DateTime date) async {
    List<ActivityLog> logs = await getLogs();
    return logs
        .where((log) =>
            log.timestamp.year == date.year &&
            log.timestamp.month == date.month &&
            log.timestamp.day == date.day)
        .toList();
  }

  // NEW: getAllLogs
  static Future<List<ActivityLog>> getAllLogs() async {
    return await getLogs();
  }

  // NEW: saveDailySummary
  static Future<void> saveDailySummary(DailySummary summary) async {
    var box = await Hive.openBox(summaryBoxName);
    await box.put(summary.date, summary.toMap());
  }

  // Optional: getDailySummary
  static Future<DailySummary?> getDailySummary(String date) async {
    var box = await Hive.openBox(summaryBoxName);
    var map = box.get(date);
    if (map != null) {
      return DailySummary.fromMap(Map<String, dynamic>.from(map));
    }
    return null;
  }

  // Optional: getAllDailySummaries
  static Future<List<DailySummary>> getAllDailySummaries() async {
    var box = await Hive.openBox(summaryBoxName);
    return box.values
        .map((m) => DailySummary.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }
}
