import 'dart:async';

import 'package:flutter/services.dart';

/// Bridges sajda://join/CODE deep links from MainActivity (native) to Dart.
/// Cold start: the link is stored natively and fetched via consumeLink().
/// Warm start: onNewIntent pushes it over the same channel (onLink).
class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService._();
  DeepLinkService._();

  static const _channel = MethodChannel('sajda/deeplink');
  final _controller = StreamController<String>.broadcast();
  bool _started = false;

  Stream<String> get links => _controller.stream;

  void start() {
    if (_started) return;
    _started = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onLink' && call.arguments is String) {
        _controller.add(call.arguments as String);
      }
      return null;
    });
    _consumePending();
  }

  Future<void> _consumePending() async {
    try {
      final link = await _channel.invokeMethod<String>('consumeLink');
      if (link != null && link.isNotEmpty) _controller.add(link);
    } catch (_) {
      // Native side unavailable (tests/desktop) — ignore.
    }
  }

  /// Returns the 6-char invite code for a sajda://join/CODE link, else null.
  String? codeFromLink(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null || uri.scheme != 'sajda' || uri.host != 'join') return null;
    final code = uri.path.replaceFirst('/', '').trim().toUpperCase();
    return RegExp(r'^[A-Z0-9]{6}$').hasMatch(code) ? code : null;
  }

  /// Parses a sajda://restore?token=...&userId=...&name=... account recovery
  /// link, else null.
  RestoreLink? restoreFromLink(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null || uri.scheme != 'sajda' || uri.host != 'restore') return null;
    final token = uri.queryParameters['token']?.trim() ?? '';
    final userId = uri.queryParameters['userId']?.trim() ?? '';
    if (token.isEmpty || userId.isEmpty) return null;
    return RestoreLink(
      token: token,
      userId: userId,
      displayName: uri.queryParameters['name']?.trim().isNotEmpty == true
          ? uri.queryParameters['name']!.trim()
          : 'User',
    );
  }
}

class RestoreLink {
  final String token;
  final String userId;
  final String displayName;

  const RestoreLink({required this.token, required this.userId, required this.displayName});
}
