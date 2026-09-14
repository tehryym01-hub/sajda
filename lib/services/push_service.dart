import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../services/streak_v2_api.dart';
import 'firebase_auth_service.dart';

/// FCM push for group streak activity (prayer ticks, day-complete).
/// The streak system NEVER depends on push: every failure here is
/// swallowed so registration or display issues can't break sign-in
/// or prayer ticks.
class PushService {
  static final PushService instance = PushService._();
  PushService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const _channel = AndroidNotificationChannel(
    'streak_activity',
    'Streak Activity',
    description: 'Group members completing prayers and streak milestones',
    importance: Importance.high,
  );
  static const int _firstId = 9500;
  bool _initialized = false;
  int _nextId = _firstId;

  /// Called whenever a backend session exists (app boot + every sign-in).
  Future<void> onSession() async {
    try {
      await FirebaseAuthService.instance.ensureInitialized();
    } catch (_) {
      return; // Firebase unavailable — push stays off, streaks still work.
    }
    try {
      await _init();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(token);
      FirebaseMessaging.instance.onTokenRefresh.listen(_register);
    } catch (_) {}
  }

  Future<void> _init() async {
    if (_initialized) return;
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    // Android heads-up: foreground FCM messages must be shown locally.
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    FirebaseMessaging.onMessage.listen(_onMessage);
    _initialized = true;
  }

  Future<void> _register(String token) async {
    try {
      await StreakV2Api.instance.registerDevice(token);
    } catch (_) {}
  }

  void _onMessage(RemoteMessage message) {
    final n = message.notification;
    final title = n?.title;
    if (title == null || title.isEmpty) return;
    _plugin.show(
      id: _nextId++,
      title: title,
      body: n?.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(n?.body ?? ''),
        ),
      ),
    );
  }
}
