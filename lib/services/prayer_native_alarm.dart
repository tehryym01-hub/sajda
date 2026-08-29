import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PrayerNativeAlarm {
  static const _channel = MethodChannel('sajda/prayer_alarm');

  static Future<bool> scheduleAlarm({
    required String prayerName,
    required int hour,
    required int minute,
    required bool isUrdu,
    required bool isReminder,
    required String mode,
    required int notificationId,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('scheduleAlarm', {
        'prayerName': prayerName,
        'hour': hour,
        'minute': minute,
        'isUrdu': isUrdu,
        'isReminder': isReminder,
        'mode': mode,
        'notificationId': notificationId,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<void> cancelAlarm(int notificationId) async {
    try {
      await _channel.invokeMethod('cancelAlarm', {'notificationId': notificationId});
    } on PlatformException catch (e) { debugPrint('cancelAlarm: $e'); }
  }

  static Future<void> cancelAll() async {
    try {
      await _channel.invokeMethod('cancelAllAlarms');
    } on PlatformException catch (e) { debugPrint('cancelAllAlarms: $e'); }
  }
}

