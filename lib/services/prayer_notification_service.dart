import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const _silentChannelId = 'prayer_azan_silent';
  static const _reminderChannelId = 'prayer_reminders';
  static const _notificationIdBase = 9000;
  static const _reminderIdBase = 8000;
  static const _channelsV2Key = 'sajda_azan_channels_v2';

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

    await _migrateAndCreateChannels();
    _initialized = true;
  }

  /// Notification channels are immutable once created. Older app versions
  /// created the azan channel without alarm audio attributes — one-time
  /// delete + recreate fixes upgraded installs WITHOUT deleting channels on
  /// every start (that used to cut off an azan mid-play).
  Future<void> _migrateAndCreateChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_channelsV2Key) ?? false;
    if (!migrated) {
      // One-time migration for upgraders.
      await android.deleteNotificationChannel(channelId: _channelId);
      await android.deleteNotificationChannel(channelId: _reminderChannelId);
      await prefs.setBool(_channelsV2Key, true);
    }

    // Full azan — alarm stream so it respects the user's alarm volume and
    // sounds like a real alarm.
    await android.createNotificationChannel(AndroidNotificationChannel(
      _channelId,
      'Prayer Azan Alerts',
      description: 'Full azan sound at every prayer time',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('adhan'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 800, 400, 800]),
      audioAttributesUsage: AudioAttributesUsage.alarm,
    ));

    // Silent azan — visual notification only, no sound, no vibration.
    await android.createNotificationChannel(AndroidNotificationChannel(
      _silentChannelId,
      'Silent Prayer Alerts',
      description: 'Silent prayer time notifications',
      importance: Importance.high,
      playSound: false,
      enableVibration: false,
    ));

    // 10-minute reminders — short default notification sound, never the
    // full adhan.
    await android.createNotificationChannel(AndroidNotificationChannel(
      _reminderChannelId,
      'Prayer Reminders',
      description: 'Reminder 10 minutes before every prayer time',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
    ));
  }

  /// Runtime notification permission only (Android 13+). Safe to call
  /// in-context, e.g. right after onboarding or when the user enables
  /// prayer alerts.
  Future<bool> requestNotificationPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  /// Notification + exact-alarm permissions. Only call from a user action
  /// (e.g. the settings toggle) — on Android 12+ the exact-alarm step opens
  /// the system settings screen.
  Future<bool> requestPermissions() async {
    final granted = await requestNotificationPermission();
    await ensureExactAlarms();
    return granted;
  }

  /// On Android 12+ exact alarms need an explicit user grant in system
  /// settings. With the inexact fallback in the native scheduler the azan
  /// still fires (within a few minutes) without it, so this is an
  /// enhancement, never a blocker.
  Future<void> ensureExactAlarms() async {
    await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return;
      final canExact = await android.canScheduleExactNotifications() ?? false;
      if (canExact) return;
      await android.requestExactAlarmsPermission();
    } catch (_) {}
  }

  /// Schedules the next occurrence of every prayer azan (+ 10-minute
  /// reminder) via native exact alarms with a +24h self-rescheduling chain,
  /// so azan keeps firing even if the app isn't opened for days.
  ///
  /// Never throws — scheduling problems are logged and skipped so a single
  /// failure can't take down every prayer alert.
  Future<void> scheduleAll(
    List<PrayerTime> prayers, {
    bool isUrdu = false,
    String timezone = 'Asia/Karachi',
    Map<String, String>? prayerModes,
    String? city,
  }) async {
    await init();
    await cancelAll();

    final now = DateTime.now();
    var id = _notificationIdBase;
    var failures = 0;
    for (final p in prayers) {
      if (p.name == 'Sunrise') continue;
      final parts = p.time.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      // Prayer times are wall-clock times in the SELECTED LOCATION's
      // timezone. Convert to an absolute epoch instant so the alarm is
      // correct even when the device timezone differs (travel etc.).
      int azanMillis;
      try {
        final loc = tz.getLocation(timezone);
        var inLoc =
            tz.TZDateTime(loc, now.year, now.month, now.day, hour, minute);
        if (!inLoc.isAfter(tz.TZDateTime.now(loc))) {
          inLoc = inLoc.add(const Duration(days: 1));
        }
        azanMillis = inLoc.millisecondsSinceEpoch;
      } catch (_) {
        var when = DateTime(now.year, now.month, now.day, hour, minute);
        if (!when.isAfter(now)) {
          when = when.add(const Duration(days: 1));
        }
        azanMillis = when.millisecondsSinceEpoch;
      }

      final pMode = prayerModes?[p.name] ?? 'full';
      if (pMode == 'mute') {
        id++;
        continue;
      }

      final prayerName =
          isUrdu ? (AppStrings.prayerNames[p.name] ?? p.name) : p.name;

      if (pMode == 'full' || pMode == 'silent') {
        final ok = await PrayerNativeAlarm.scheduleAlarm(
          prayerName: prayerName,
          triggerAtMillis: azanMillis,
          hour: hour,
          minute: minute,
          isUrdu: isUrdu,
          isReminder: false,
          mode: pMode,
          notificationId: id,
          city: city,
        );
        if (!ok) failures++;
      }

      // Reminder 10 minutes before; if that moment already passed, take
      // tomorrow's reminder instead of firing late.
      var reminderMillis = azanMillis - const Duration(minutes: 10).inMilliseconds;
      if (reminderMillis <= now.millisecondsSinceEpoch) {
        reminderMillis +=
            const Duration(days: 1).inMilliseconds;
      }
      final reminderOk = await PrayerNativeAlarm.scheduleAlarm(
        prayerName: prayerName,
        triggerAtMillis: reminderMillis,
        hour: hour,
        minute: minute,
        isUrdu: isUrdu,
        isReminder: true,
        mode: pMode,
        notificationId: _reminderIdBase + (id - _notificationIdBase),
        city: city,
      );
      if (!reminderOk) failures++;

      id++;
    }
    if (failures > 0) {
      debugPrint('PrayerNotificationService: $failures alarm(s) failed to schedule');
    }
  }

  NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Prayer Azan Alerts',
          channelDescription: 'Full azan sound at every prayer time',
          importance: Importance.max,
          priority: Priority.max,
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

  /// Fires a test azan notification immediately (used by the preview in
  /// settings).
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
