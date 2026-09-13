import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/streak_v2.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/streak_v2_api.dart';

enum StreakLoadPhase { idle, loading, ready, error }

/// Central state for the v2 streak system (Solo + Friends & Family groups).
///
/// The backend is authoritative: every method applies server state to the
/// UI. The one canonical prayer tick (`togglePrayer`) updates Solo AND every
/// group from a single response. Local caches exist only for UX speed.
class StreakState extends ChangeNotifier {
  // ── Solo ──
  SoloStreakData? _solo;
  StreakLoadPhase _soloPhase = StreakLoadPhase.idle;
  String? _soloError;

  SoloStreakData? get solo => _solo;
  StreakLoadPhase get soloPhase => _soloPhase;
  String? get soloError => _soloError;

  // ── My groups ──
  List<GroupSummary> _groups = [];
  StreakLoadPhase _groupsPhase = StreakLoadPhase.idle;
  String? _groupsError;

  List<GroupSummary> get groups => List.unmodifiable(_groups);
  StreakLoadPhase get groupsPhase => _groupsPhase;
  String? get groupsError => _groupsError;
  List<GroupSummary> get activeGroups => _groups.where((g) => !g.archived).toList();

  // ── Notifications (in-app feed; actor never sees own actions) ──
  int _unreadCount = 0;
  List<NotificationItem> _notifications = [];
  int get unreadCount => _unreadCount;
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  // ── In-flight guards (no duplicate submissions) ──
  final Set<String> _prayersInFlight = {};

  /// True while [prayer]'s request is on the wire (per-prayer lock so the
  /// user can still tap other prayers).
  bool isPrayerInFlight(String prayer) => _prayersInFlight.contains(prayer);

  bool _authenticated = false;
  bool get authenticated => _authenticated;

  final StreakV2Api _api = StreakV2Api.instance;

  /// Entry point — call on app start / streak screen open / auth change.
  Future<void> initialize() async {
    _authenticated = AuthService.instance.isAuthenticated;
    if (!_authenticated) {
      _solo = null;
      _groups = [];
      _notifications = [];
      _unreadCount = 0;
      _soloPhase = StreakLoadPhase.idle;
      _groupsPhase = StreakLoadPhase.idle;
      notifyListeners();
      return;
    }
    await Future.wait([refreshSolo(silent: true), refreshGroups(silent: true)]);
    unawaited(refreshNotifications());
  }

  Future<bool> _recoverAuth() async {
    await AuthService.instance.clear();
    try {
      await AuthService.instance.login();
      _authenticated = AuthService.instance.isAuthenticated;
      return _authenticated;
    } catch (_) {
      return false;
    }
  }

  Future<T> _withAuthRecovery<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (e) {
      if (!e.isAuthError) rethrow;
      if (await _recoverAuth()) return await action();
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // SOLO + GROUPS + NOTIFICATIONS
  // ─────────────────────────────────────────────────────────────────────

  Future<void> refreshSolo({bool silent = false}) async {
    if (!AuthService.instance.isAuthenticated) return;
    if (!silent) {
      _soloPhase = StreakLoadPhase.loading;
      notifyListeners();
    }
    try {
      final data = await _withAuthRecovery(_api.getSolo);
      _solo = data;
      _soloPhase = StreakLoadPhase.ready;
      _soloError = null;
    } on ApiException catch (e) {
      if (e.isAuthError) {
        _authenticated = false;
      }
      _soloPhase = StreakLoadPhase.error;
      _soloError = e.isNetworkError ? 'network' : e.toString();
    } catch (e) {
      _soloPhase = StreakLoadPhase.error;
      _soloError = e.toString();
    }
    notifyListeners();
  }

  Future<void> refreshGroups({bool silent = false}) async {
    if (!AuthService.instance.isAuthenticated) return;
    if (!silent) {
      _groupsPhase = StreakLoadPhase.loading;
      notifyListeners();
    }
    try {
      final data = await _withAuthRecovery(_api.getMyGroups);
      _groups = data;
      _groupsPhase = StreakLoadPhase.ready;
      _groupsError = null;
    } on ApiException catch (e) {
      if (e.isAuthError) _authenticated = false;
      _groupsPhase = StreakLoadPhase.error;
      _groupsError = e.isNetworkError ? 'network' : e.toString();
    } catch (e) {
      _groupsPhase = StreakLoadPhase.error;
      _groupsError = e.toString();
    }
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    if (!AuthService.instance.isAuthenticated) return;
    try {
      final feed = await _withAuthRecovery(_api.getNotifications);
      _notifications = feed.items;
      _unreadCount = feed.unread;
    } catch (_) {
      // Notifications are supplementary — never break flows on them.
    }
    notifyListeners();
  }

  Future<void> markNotificationsSeen() async {
    _unreadCount = 0;
    notifyListeners();
    try {
      await _api.markNotificationsSeen();
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────
  // THE ONE PRAYER TICK — updates Solo + ALL groups from one response.
  // ─────────────────────────────────────────────────────────────────────

  /// Returns null on success, or an error message. Optimistic local state
  /// is applied immediately; the authoritative server response overwrites
  /// it (and group lists refresh from the fan-out result).
  Future<String?> togglePrayer(String prayer, bool completed) async {
    if (_prayersInFlight.contains(prayer)) return null;
    _prayersInFlight.add(prayer);

    // Optimistic solo state for instant feedback.
    if (_solo != null) {
      _solo = _solo!.copyWith(today: _solo!.today.withPrayer(prayer, completed));
      notifyListeners();
    }

    try {
      final result = await _withAuthRecovery(() => _api.completePrayer(prayer, completed: completed));
      _solo = result.solo;
      notifyListeners();
      // Groups were touched by the same tick — refresh their summaries
      // quietly so every group card/dashboard reflects the fan-out.
      unawaited(refreshGroups(silent: true));
      unawaited(refreshNotifications());
      return null;
    } on ApiException catch (e) {
      // Roll back optimistic state to the last authoritative snapshot.
      await refreshSolo(silent: true);
      return e.isNetworkError
          ? 'network'
          : e.toString();
    } catch (e) {
      await refreshSolo(silent: true);
      return e.toString();
    } finally {
      _prayersInFlight.remove(prayer);
    }
  }

  Future<String?> startSolo() async {
    try {
      final data = await _withAuthRecovery(_api.startSolo);
      _solo = data;
      _soloPhase = StreakLoadPhase.ready;
      notifyListeners();
      return null;
    } catch (e) {
      return e is ApiException && e.isNetworkError ? 'network' : e.toString();
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // GROUP OPERATIONS (screens own navigation; state stays consistent)
  // ─────────────────────────────────────────────────────────────────────

  Future<String?> createGroup(String name, {bool public = false}) async {
    try {
      await _withAuthRecovery(() => _api.createGroup(name, public: public));
      await refreshGroups(silent: true);
      return null;
    } on ApiException catch (e) {
      return e.isNetworkError ? 'network' : e.toString();
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> leaveGroup(String groupId) async {
    try {
      await _withAuthRecovery(() => _api.leaveGroup(groupId));
      await refreshGroups(silent: true);
      return null;
    } on ApiException catch (e) {
      return e.isNetworkError ? 'network' : e.toString();
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> archiveGroup(String groupId) async {
    try {
      await _withAuthRecovery(() => _api.archiveGroup(groupId));
      await refreshGroups(silent: true);
      return null;
    } on ApiException catch (e) {
      return e.isNetworkError ? 'network' : e.toString();
    } catch (e) {
      return e.toString();
    }
  }

  /// Used after any mutation from a group screen to keep cards in sync.
  Future<void> groupsChanged() => refreshGroups(silent: true);

  void reset() {
    _solo = null;
    _groups = [];
    _notifications = [];
    _unreadCount = 0;
    _soloPhase = StreakLoadPhase.idle;
    _groupsPhase = StreakLoadPhase.idle;
    _soloError = null;
    _groupsError = null;
    _authenticated = false;
    notifyListeners();
  }
}
