import 'dart:async';
import 'package:flutter/services.dart';

/// Bridges Dart prayer scheduling to the native AlarmManager implementation.
///
/// [triggerAtMillis] is an absolute epoch-millis instant (already converted
/// from the selected location's timezone to a device-clock instant), so the
/// alarm fires at the correct moment regardless of the device's timezone.
class PrayerNativeAlarm {
  static const _channel = MethodChannel('sajda/prayer_alarm');

  static Future<bool> scheduleAlarm({
    required String prayerName,
    required int triggerAtMillis,
    required int hour,
    required int minute,
    required bool isUrdu,
    required bool isReminder,
    required String mode,
    required int notificationId,
    String? city,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('scheduleAlarm', {
        'prayerName': prayerName,
        'triggerAtMillis': triggerAtMillis,
        'hour': hour,
        'minute': minute,
        'isUrdu': isUrdu,
        'isReminder': isReminder,
        'mode': mode,
        'notificationId': notificationId,
        if (city != null && city.isNotEmpty) 'city': city,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<void> cancelAlarm(int notificationId) async {
    try {
      await _channel.invokeMethod('cancelAlarm', {'notificationId': notificationId});
    } on PlatformException catch (_) {}
  }

  static Future<void> cancelAll() async {
    try {
      await _channel.invokeMethod('cancelAllAlarms');
    } on PlatformException catch (_) {}
  }
}
