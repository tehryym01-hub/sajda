import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  static const _kToken = 'sajda_auth_token';
  static const _kDeviceId = 'sajda_device_id';
  static const _kUserId = 'sajda_user_id';
  static const _kDisplayName = 'sajda_display_name';

  String? _token;
  String? _deviceId;
  String? _userId;
  String? _displayName;

  String? get token => _token;
  String? get deviceId => _deviceId;
  String? get userId => _userId;
  String? get displayName => _displayName;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _deviceId = prefs.getString(_kDeviceId);
    _userId = prefs.getString(_kUserId);
    _displayName = prefs.getString(_kDisplayName);
  }

  Future<void> saveAuth({
    required String token,
    required String userId,
    required String displayName,
    String? deviceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _token = token;
    _userId = userId;
    _displayName = displayName;
    _deviceId = deviceId ?? _deviceId;
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUserId, userId);
    await prefs.setString(_kDisplayName, displayName);
    if (deviceId != null) {
      _deviceId = deviceId;
      await prefs.setString(_kDeviceId, deviceId);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    _token = null;
    _userId = null;
    _displayName = null;
    _deviceId = null;
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
    await prefs.remove(_kDisplayName);
    await prefs.remove(_kDeviceId);
  }

  Future<String> getDeviceId() async {
    if (_deviceId != null && _deviceId!.isNotEmpty) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_kDeviceId);
    if (_deviceId == null || _deviceId!.isEmpty) {
      final random = Random.secure();
        final bytes = List<int>.generate(16, (_) => random.nextInt(256));
        _deviceId = base64UrlEncode(bytes);
      await prefs.setString(_kDeviceId, _deviceId!);
    }
    return _deviceId!;
  }

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: authHeaders,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) throw AuthException('HTTP ${res.statusCode}');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw AuthException(json['message']?.toString() ?? 'Auth error');
    }
    return json;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: authHeaders,
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) throw AuthException('HTTP ${res.statusCode}');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw AuthException(json['message']?.toString() ?? 'Request failed');
    }
    return json;
  }

  Future<Map<String, dynamic>> register(String displayName) async {
    final deviceId = await getDeviceId();
    final json = await _post('/auth/register', {
      'displayName': displayName.trim(),
      'deviceId': deviceId,
    });
    final data = json['data'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    final token = data['token'] as String;
    await saveAuth(
      token: token,
      userId: user['_id']?.toString() ?? user['id']?.toString() ?? '',
      displayName: user['displayName']?.toString() ?? displayName,
      deviceId: deviceId,
    );
    return data;
  }

  Future<Map<String, dynamic>> login() async {
    final deviceId = await getDeviceId();
    final json = await _post('/auth/login', {'deviceId': deviceId});
    final data = json['data'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    final token = data['token'] as String;
    await saveAuth(
      token: token,
      userId: user['_id']?.toString() ?? user['id']?.toString() ?? '',
      displayName: user['displayName']?.toString() ?? '',
      deviceId: deviceId,
    );
    return data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final json = await _get('/auth/profile');
    final data = json['data'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    _displayName = user['displayName']?.toString() ?? _displayName;
    _userId = user['_id']?.toString() ?? user['id']?.toString() ?? _userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDisplayName, _displayName ?? '');
    await prefs.setString(_kUserId, _userId ?? '');
    return data;
  }

  Future<void> updateProfile({String? displayName, String? timezone, String? city, String? country}) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName.trim();
    if (timezone != null) body['timezone'] = timezone;
    if (city != null) body['city'] = city;
    if (country != null) body['country'] = country;
    if (body.isEmpty) return;
    await _post('/auth/profile', body);
    if (displayName != null) {
      _displayName = displayName.trim();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDisplayName, _displayName!);
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}




