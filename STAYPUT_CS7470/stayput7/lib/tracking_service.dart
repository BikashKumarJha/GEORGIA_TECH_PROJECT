// tracking_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'models.dart';
import 'storage_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class TrackingService {
  Timer? _timer;

  Future<void> init() async {
    await _initNotifications();
    await _requestPermissions();
    _startForegroundTimer();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> _requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }
  }

  void _startForegroundTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );

        // Determine nearest place
        List<Place> places = await StorageService.getPlaces();
        String placeName = "Other";
        for (var place in places) {
          double distance = Geolocator.distanceBetween(
              pos.latitude, pos.longitude, place.latitude, place.longitude);
          if (distance < 50) {
            placeName = place.name;
            break;
          }
        }

        // Save log to Hive
        await StorageService.saveLog(
          ActivityLog(
            timestamp: DateTime.now(),
            activity: 'unknown',
            placeName: placeName,
          ),
        );

        // Show temporary 2-second heads-up notification
        _showTemporaryNotification(
          'Location Saved',
          '$placeName (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
        );
      } catch (e) {
        // fail silently
      }
    });
  }

  void _showTemporaryNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'stayput_channel',
      'StayPut Tracking',
      channelDescription: 'Shows location tracking updates',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Location Saved',
      playSound: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    const int notificationId = 0;

    // Show notification
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformDetails,
    );

    // Automatically cancel after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      flutterLocalNotificationsPlugin.cancel(notificationId);
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
