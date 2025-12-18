// native_service.dart
import 'dart:async';
import 'package:flutter/services.dart';

class NativeService {
  static const MethodChannel _channel = MethodChannel('com.stayput7.service');

  /// Start the native location foreground service.
  static Future<void> start() async {
    try {
      await _channel.invokeMethod('startService');
    } on PlatformException catch (e) {
      print('Failed to start native service: ${e.message}');
    }
  }

  /// Stop the native location foreground service.
  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopService');
    } on PlatformException catch (e) {
      print('Failed to stop native service: ${e.message}');
    }
  }
}
