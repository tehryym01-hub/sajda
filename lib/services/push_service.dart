import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../screens/group_dashboard_screen.dart';
import '../screens/group_settings_screen.dart';
import '../services/streak_v2_api.dart';
import 'firebase_auth_service.dart';

/// FCM push for group streak activity (prayer ticks, day-complete, join
/// requests). The streak system NEVER depends on push: every failure here
/// is swallowed so registration or display issues can't break sign-in
/// or prayer ticks.
class PushService {
  static final PushService instance = PushService._();
  PushService._();

  /// Root navigator for notification-tap routing (wired in main.dart).
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const _channel = AndroidNotificationChannel(
    'streak_activity',
    'Streak Activity',
    description: 'Group members completing prayers and streak milestones',
    importance: Importance.high,
  );
  static const int _firstId = 9500;
  bool _initialized = false;
  bool _listenersSet = false;
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
      if (!_listenersSet) {
        _listenersSet = true;
        FirebaseMessaging.instance.onTokenRefresh.listen(_register);
      }
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
      onDidReceiveNotificationResponse: _onLocalTap,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    FirebaseMessaging.onMessage.listen(_onMessage);
    // Taps: app open in background, or cold-start from a terminated state.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTapMessage);
    unawaited(
      FirebaseMessaging.instance.getInitialMessage().then((m) {
        if (m != null) _handleTapMessage(m);
      }),
    );
    _initialized = true;
  }

  Future<void> _register(String token) async {
    try {
      await StreakV2Api.instance.registerDevice(token);
    } catch (e) {
      // Never fatal, but never silent either — a device that never
      // registers is exactly why push audits show zero tokens.
      debugPrint('[PushService] registerDevice failed: $e');
    }
  }

  void _onMessage(RemoteMessage message) {
    final n = message.notification;
    final title = n?.title;
    if (title == null || title.isEmpty) return;
    _plugin.show(
      id: _nextId++,
      title: title,
      body: n?.body,
      payload: jsonEncode(message.data),
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

  // ── Tap routing ──

  void _onLocalTap(NotificationResponse response) {
    final raw = response.payload;
    if (raw == null || raw.isEmpty) return;
    try {
      _routePush(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
  }

  void _handleTapMessage(RemoteMessage message) {
    _routePush(message.data);
  }

  /// join_request / member_joined → owners and admins land directly on the
  /// approve/decline tab of group settings; everyone else (and join_decided
  /// approvals) lands on the group dashboard.
  Future<void> _routePush(Map<String, dynamic> data) async {
    final type = data['type']?.toString();
    if (type != 'join_request' && type != 'member_joined' && type != 'join_decided') {
      return;
    }
    if (type == 'join_decided' && data['approved']?.toString() != 'true') {
      return; // nothing to open for a declined request
    }
    final groupId = data['groupId']?.toString();
    if (groupId == null || groupId.isEmpty) return;
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    Widget screen = GroupDashboardScreen(groupId: groupId);
    if (type == 'join_request' || type == 'member_joined') {
      try {
        final dash = await StreakV2Api.instance.getGroupDashboard(groupId);
        final role = dash.group.myRole;
        if (role == 'owner' || role == 'admin') {
          screen = GroupSettingsScreen(group: dash.group, initialTab: 1);
        }
      } catch (_) {
        // Dashboard alone is the safe fallback (it loads its own data).
      }
    }
    try {
      nav.push(MaterialPageRoute(builder: (_) => screen));
    } catch (_) {}
  }
}
