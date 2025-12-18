class Place {
  String name;
  double latitude;
  double longitude;

  Place({required this.name, required this.latitude, required this.longitude});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      name: map['name'],
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}

class ActivityLog {
  DateTime timestamp;
  String activity; // walking, driving, stationary
  String placeName; // place name or "Other"

  ActivityLog(
      {required this.timestamp,
      required this.activity,
      required this.placeName});

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'activity': activity,
      'placeName': placeName,
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      timestamp: DateTime.parse(map['timestamp']),
      activity: map['activity'],
      placeName: map['placeName'],
    );
  }
}

// NEW: DailySummary model
class DailySummary {
  String date; // YYYY-MM-DD
  Map<String, double> placeDurations; // placeName -> hours

  DailySummary({required this.date, required this.placeDurations});

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'placeDurations': placeDurations,
    };
  }

  factory DailySummary.fromMap(Map<String, dynamic> map) {
    return DailySummary(
      date: map['date'],
      placeDurations: Map<String, double>.from(map['placeDurations']),
    );
  }
}
