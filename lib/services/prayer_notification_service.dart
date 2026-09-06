import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../config.dart';
import '../models/models.dart';
import 'prayer_native_alarm.dart';

class PrayerNotificationService {
  static final PrayerNotificationService instance =
      PrayerNotificationService._();
  PrayerNotificationService._();

  static const _channelId = 'prayer_azan_alerts';
  static const _reminderChannelId = 'prayer_reminders';
  static const _notificationIdBase = 9000;
  static const _reminderIdBase = 8000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init({String? userTimezone}) async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    // Prefer the user's selected-location timezone; otherwise use the device
    // timezone; ultimate fallback Asia/Karachi.
    var resolved = false;
    if (userTimezone != null && userTimezone.isNotEmpty) {
      try {
        tz.setLocalLocation(tz.getLocation(userTimezone));
        resolved = true;
      } catch (_) {}
    }
    if (!resolved) {
      try {
        final tzInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
      }
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings:
          const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.deleteNotificationChannel(channelId: _channelId);
    await android?.deleteNotificationChannel(channelId: _reminderChannelId);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(AndroidNotificationChannel(
          _channelId,
          'Prayer Azan Alerts',
          description: 'Prayer time alerts',
          importance: Importance.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('adhan'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 800, 400, 800]),
        ));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(AndroidNotificationChannel(
          _reminderChannelId,
          'Prayer Reminders',
          description: 'Reminder 10 minutes before every prayer time',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
        ));

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission() ?? true;
    await _ensureExactAlarms();
    return granted;
  }

  /// On Android 12+ exact alarms need an explicit grant. We request it so the
  /// azan can fire precisely at prayer time (release builds otherwise silently
  /// lose the permission and fall back to inexact scheduling).
  Future<void> _ensureExactAlarms() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return;
      final canExact = await android.canScheduleExactNotifications() ?? false;
      if (canExact) return;
      await android.requestExactAlarmsPermission();
    } catch (_) {}
  }

  Future<void> scheduleAll(
    List<PrayerTime> prayers, {
    bool isUrdu = false,
    String timezone = 'Asia/Karachi',
    Map<String, String>? prayerModes,
  }) async {
    await init();
    await cancelAll();

    final now = DateTime.now();
    var id = _notificationIdBase;
    final errors = <String>[];
    for (final p in prayers) {
      if (p.name == 'Sunrise') continue;
      final parts = p.time.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      // Prayer times are wall-clock times in the SELECTED LOCATION's timezone.
      // Native alarms fire on the device clock, so convert the location-tz
      // instant into the equivalent device-local DateTime before scheduling.
      DateTime when;
      try {
        final loc = tz.getLocation(timezone);
        var inLoc = tz.TZDateTime(loc, now.year, now.month, now.day, hour, minute);
        if (!inLoc.isAfter(tz.TZDateTime.now(loc))) {
          inLoc = inLoc.add(const Duration(days: 1));
        }
        when = DateTime.fromMillisecondsSinceEpoch(inLoc.millisecondsSinceEpoch);
      } catch (_) {
        when = DateTime(now.year, now.month, now.day, hour, minute);
        if (when.isBefore(now)) {
          when = when.add(const Duration(days: 1));
        }
      }

      final pMode = prayerModes?[p.name] ?? 'full';
      if (pMode == 'mute') {
        id++;
        continue;
      }

      final prayerName = isUrdu
          ? (AppStrings.prayerNames[p.name] ?? p.name)
          : p.name;

      try {
        final success = await PrayerNativeAlarm.scheduleAlarm(
          prayerName: prayerName,
          hour: hour,
          minute: minute,
          isUrdu: isUrdu,
          isReminder: false,
          mode: pMode,
          notificationId: id,
        );
        if (!success) {
          errors.add('$prayerName ${p.time}: native alarm failed');
        }
      } catch (e) {
        errors.add('$prayerName ${p.time}: $e');
      }

      if (pMode != 'mute') {
        try {
          final reminderWhen = when.subtract(const Duration(minutes: 10));
          final success = await PrayerNativeAlarm.scheduleAlarm(
            prayerName: prayerName,
            hour: reminderWhen.hour,
            minute: reminderWhen.minute,
            isUrdu: isUrdu,
            isReminder: true,
            mode: pMode,
            notificationId: _reminderIdBase + (id - _notificationIdBase),
          );
          if (!success) {
            errors.add('Reminder $prayerName ${p.time}: native alarm failed');
          }
        } catch (e) {
          errors.add('Reminder $prayerName ${p.time}: $e');
        }
      }
      id++;
    }
    if (errors.isNotEmpty) {
      throw Exception('Failed to schedule ${errors.length} prayers: ${errors.join(' | ')}');
    }
  }

  NotificationDetails _details({bool playSound = true}) => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Prayer Azan Alerts',
          channelDescription: 'Prayer time alerts',
          importance: Importance.max,
          priority: Priority.max,
          playSound: playSound,
          category: AndroidNotificationCategory.alarm,
        ),
      );

  Future<void> _cancelPrayerIds() async {
    final futures = <Future>[];
    for (var id = _notificationIdBase; id < _notificationIdBase + 10; id++) {
      futures.add(_plugin.cancel(id: id).catchError((_) {}));
    }
    for (var id = _reminderIdBase; id < _reminderIdBase + 10; id++) {
      futures.add(_plugin.cancel(id: id).catchError((_) {}));
    }
    await Future.wait(futures);
  }

  Future<void> cancelAll() async {
    await init();
    await _cancelPrayerIds();
    await PrayerNativeAlarm.cancelAll();
  }

  Future<void> showNow(String prayerName, {bool isUrdu = false}) async {
    await init();
    final title = isUrdu ? 'وقتِ نماز: $prayerName' : 'Prayer time: $prayerName';
    try {
      await _plugin.show(
        id: _notificationIdBase + 99,
        title: title,
        body: isUrdu ? 'اللہ اکبر، اللہ اکبر' : 'Allahu Akbar, Allahu Akbar',
        notificationDetails: _details(),
      );
    } catch (_) {}
  }

  Future<List<PendingNotificationRequest>> pendingRequests() async {
    await init();
    return _plugin.pendingNotificationRequests();
  }

  Future<bool> exactAlarmsAllowed() async {
    await init();
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.canScheduleExactNotifications() ??
        true;
  }
}