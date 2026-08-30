import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'package:intl/intl.dart';
import '../services/hijri_date_service.dart';
import '../services/auth_service.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  final String _base = AppConfig.apiBaseUrl;

  PrayerTimesResponse? _cachedPrayerTimes;
  DateTime? _prayerTimesCacheTime;

  PrayerTimesResponse? get cachedPrayerTimes {
    if (_cachedPrayerTimes == null || _prayerTimesCacheTime == null) return null;
    if (DateTime.now().difference(_prayerTimesCacheTime!) > const Duration(hours: 1)) {
      _cachedPrayerTimes = null;
      _prayerTimesCacheTime = null;
      return null;
    }
    return _cachedPrayerTimes;
  }

  void invalidatePrayerTimesCache() {
    _cachedPrayerTimes = null;
    _prayerTimesCacheTime = null;
  }

  Map<String, String> _headers() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = AuthService.instance.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _unwrap(http.Response res) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Server returned invalid response');
    }
    if (json['success'] != true) {
      throw ApiException(json['message']?.toString() ?? 'API error');
    }
    return json;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(Uri.parse('$_base$path'), headers: _headers())
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      try {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        throw ApiException(json['message']?.toString() ?? 'HTTP ${res.statusCode}');
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('HTTP ${res.statusCode}');
      }
    }
    return _unwrap(res);
  }

  Future<Map<String, dynamic>> get(String path) => _get(path);

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: _headers(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      try {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        throw ApiException(json['message']?.toString() ?? 'HTTP ${res.statusCode}');
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('HTTP ${res.statusCode}');
      }
    }
    return _unwrap(res);
  }

  // ---------- Prayer ----------

  Future<PrayerTimesResponse> getPrayerTimes(String city, String country) async {
    final json = await _get('/prayers/times?city=${Uri.encodeQueryComponent(city)}&country=${Uri.encodeQueryComponent(country)}');
    return PrayerTimesResponse.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<PrayerTimesResponse> getPrayerTimesForDate(
      String city, String country, DateTime date) async {
    final d =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final json = await _get(
        '/prayers/times?city=${Uri.encodeQueryComponent(city)}&country=${Uri.encodeQueryComponent(country)}&date=$d');
    return PrayerTimesResponse.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<PrayerTimesResponse> getPrayerTimesByCoords(double lat, double lng) async {
    final json = await _get('/prayers/times?lat=$lat&lng=$lng');
    return PrayerTimesResponse.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<PrayerTimesResponse> getPrayerTimesFor(AppState state, {bool useCache = true}) async {
    if (useCache) {
      final cached = cachedPrayerTimes;
      if (cached != null) return cached;
    }
    final lat = state.lat ?? 0.0;
    final lng = state.lng ?? 0.0;
    final city = state.prayerCityParam;
    final country = state.prayerCountryParam;
    final timezone = state.locationTimezone;
    final date = DateTime.now();
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final method = state.prayerMethod;
    final school = state.asrSchool;

    PrayerTimesResponse result;
    if (lat != 0.0 && lng != 0.0) {
      try {
        result = await _getAladhanPrayerTimes(lat, lng, timezone, dateStr, method, school);
      } catch (_) {
        result = await getPrayerTimes(city, country);
      }
    } else {
      result = await getPrayerTimes(city, country);
    }
    _cachedPrayerTimes = result;
    _prayerTimesCacheTime = DateTime.now();
    return result;
  }

  Future<PrayerTimesResponse> _getAladhanPrayerTimes(
      double lat, double lng, String timezone, String dateStr, int method, int school) async {
    final uri = Uri.parse(
        'https://api.aladhan.com/v1/timings/$dateStr?latitude=$lat&longitude=$lng&timezone=${Uri.encodeQueryComponent(timezone)}&method=$method&school=$school');
    final res = await http.get(uri, headers: {'User-Agent': 'SajdaDataplus/1.0'});
    if (res.statusCode >= 400) throw ApiException('AlAdhan HTTP ${res.statusCode}');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['code'] != 200) throw ApiException('AlAdhan API error');
    final timings = json['data']['timings'] as Map<String, dynamic>;
    final prayers = <PrayerTime>[];
    for (final name in ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
      final time = timings[name]?.toString() ?? '';
      if (time.isNotEmpty) prayers.add(PrayerTime(name, time));
    }

    final dateParts = dateStr.split('-');
    final gregorianDate = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );
    final hijriInfo = HijriDateService.getHijriDate(gregorianDate);

    final hijriInfoModel = HijriInfo(
      day: hijriInfo.day.toString(),
      month: hijriInfo.monthEn,
      monthAr: hijriInfo.monthAr,
      year: hijriInfo.year.toString(),
      full: hijriInfo.full,
      fullAr: hijriInfo.fullAr,
      monthNumber: hijriInfo.month,
    );
    return PrayerTimesResponse(prayers: prayers, date: dateStr, hijri: hijriInfoModel);
  }

  Future<NextPrayerResponse> getNextPrayer(String city, String country) async {
    final json = await _get('/prayers/next-prayer?city=${Uri.encodeQueryComponent(city)}&country=${Uri.encodeQueryComponent(country)}');
    return NextPrayerResponse.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<NextPrayerResponse> getNextPrayerByCoords(AppState state) async {
    final lat = state.lat ?? 0.0;
    final lng = state.lng ?? 0.0;
    final timezone = state.locationTimezone;
    final date = DateTime.now();
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final method = state.prayerMethod;
    final school = state.asrSchool;

    if (lat != 0.0 && lng != 0.0) {
      try {
        final uri = Uri.parse(
            'https://api.aladhan.com/v1/timings/$dateStr?latitude=$lat&longitude=$lng&timezone=${Uri.encodeQueryComponent(timezone)}&method=$method&school=$school');
    final res = await http.get(uri, headers: {'User-Agent': 'SajdaDataplus/1.0'});
        if (res.statusCode >= 400) throw ApiException('AlAdhan HTTP ${res.statusCode}');
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['code'] != 200) throw ApiException('AlAdhan API error');
        final timings = json['data']['timings'] as Map<String, dynamic>;
        final prayers = <PrayerTime>[];
        for (final name in ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
          final time = timings[name]?.toString() ?? '';
          if (time.isNotEmpty) prayers.add(PrayerTime(name, time));
        }

        final gregorianDate = DateTime.now();
        final hijriInfo = HijriDateService.getHijriDate(gregorianDate);

        final hijriInfoModel = HijriInfo(
          day: hijriInfo.day.toString(),
          month: hijriInfo.monthEn,
          monthAr: hijriInfo.monthAr,
          year: hijriInfo.year.toString(),
          full: hijriInfo.full,
          fullAr: hijriInfo.fullAr,
          monthNumber: hijriInfo.month,
        );
        final currentTime = DateFormat('HH:mm').format(DateTime.now());
        final now = DateTime.now();
        final currentMinutes = now.hour * 60 + now.minute;
        final prayerTimes = prayers.map((p) {
          final parts = p.time.split(':');
          if (parts.length == 2) {
            return {'name': p.name, 'time': p.time, 'totalMinutes': int.parse(parts[0]) * 60 + int.parse(parts[1])};
          }
          return null;
        }).whereType<Map<String, dynamic>>().toList();
        
        final nextPrayers = prayerTimes.where((p) => (p['totalMinutes'] as int) > currentMinutes).toList();
        
        Map<String, dynamic> next;
        if (nextPrayers.isEmpty) {
          next = prayerTimes.firstWhere((p) => p['name'] == 'Fajr');
          next['isTomorrow'] = true;
        } else {
          next = nextPrayers.first;
          next['isTomorrow'] = false;
        }
        
        return NextPrayerResponse(
          currentTime: currentTime,
          name: next['name'],
          time: next['time'],
          totalMinutes: next['totalMinutes'],
          isTomorrow: next['isTomorrow'],
          countdown: next['isTomorrow'] 
              ? ((24 * 60 - currentMinutes) + (next['totalMinutes'] as int)) * 60
              : ((next['totalMinutes'] as int) - currentMinutes) * 60,
          allPrayers: prayers,
          hijri: hijriInfoModel,
        );
      } catch (_) {
        // Fallback to backend
      }
    }
    final city = state.prayerCityParam;
    final country = state.prayerCountryParam;
    final json = await _get('/prayers/next-prayer?city=${Uri.encodeQueryComponent(city)}&country=${Uri.encodeQueryComponent(country)}');
    return NextPrayerResponse.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<QiblaResponse> getQibla(double lat, double lng) async {
    final json = await _get('/qibla/direction?lat=$lat&lng=$lng');
    return QiblaResponse.fromJson(json['data'] as Map<String, dynamic>);
  }

  // ---------- Events ----------

  Future<List<IslamicEvent>> getTodayEvents() async {
    final json = await _get('/events/today');
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return (data['events'] as List? ?? [])
        .map((e) => IslamicEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<IslamicEvent>> getMonthEvents(String month) async {
    final json = await _get('/events/month/$month');
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return (data['events'] as List? ?? [])
        .map((e) => IslamicEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<IslamicEvent>> getUpcomingEvents({int limit = 10}) async {
    final json = await _get('/events/upcoming?limit=$limit');
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return (data['events'] as List? ?? [])
        .map((e) => IslamicEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------- Duas ----------

  Future<List<DuaModel>> getDuas({String? category}) async {
    final json = await _get('/duas${category != null ? '?category=$category' : ''}');
    return (json['data'] as List? ?? [])
        .map((e) => DuaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DuaModel?> getDailyDua() async {
    final json = await _get('/duas/daily');
    final data = json['data'];
    return data == null ? null : DuaModel.fromJson(data as Map<String, dynamic>);
  }

  // ---------- Wazifa ----------

  Future<WazifaModel?> getDailyWazifa() async {
    final json = await _get('/wazifas/daily');
    final data = json['data'];
    return data == null ? null : WazifaModel.fromJson(data as Map<String, dynamic>);
  }

  Future<WazifaModel?> getWazifaByDay(int day) async {
    final json = await _get('/wazifas/day/$day');
    final data = json['data'];
    return data == null ? null : WazifaModel.fromJson(data as Map<String, dynamic>);
  }

  // ---------- Hijri ----------

  Future<HijriToday> getHijriToday() async {
    final json = await _get('/hijri/today');
    return HijriToday.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<HijriDay>> getHijriCalendar({int? month, int? year}) async {
    final params = <String>[];
    if (month != null) params.add('month=$month');
    if (year != null) params.add('year=$year');
    final q = params.isEmpty ? '' : '?${params.join('&')}';
    final json = await _get('/hijri/calendar$q');
    return (json['data'] as List? ?? [])
        .map((e) => HijriDay.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------- Streak ----------

  Future<Map<String, dynamic>> getMyStreak() async {
    final json = await _get('/streak/my-streak');
    return json['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPersonalStreak(int goalDays) async {
    final json = await _post('/streak/personal', {'goalDays': goalDays});
    return json['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePrayerCompletion({
    required String prayer,
    required bool completed,
    String? date,
    String? timezone,
  }) async {
    final body = <String, dynamic>{
      'prayer': prayer,
      'completed': completed,
    };
    if (date != null) body['date'] = date;
    if (timezone != null) body['timezone'] = timezone;
    final json = await _post('/streak/completion', body);
    return json['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> pauseStreak() async {
    final json = await _post('/streak/pause', {});
    return json['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resumeStreak() async {
    final json = await _post('/streak/resume', {});
    return json['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getStreakHistory() async {
    final json = await _get('/streak/history');
    return json['data']?['history'] as List<dynamic>? ?? [];
  }

  Future<List<dynamic>> getStreakCalendar({int? year, int? month}) async {
    final params = <String>[];
    if (year != null) params.add('year=$year');
    if (month != null) params.add('month=$month');
    final q = params.isEmpty ? '' : '?${params.join('&')}';
    final json = await _get('/streak/calendar$q');
    return json['data']?['calendar'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> createSharedStreak({required int goalDays, String? title}) async {
    final body = <String, dynamic>{'goalDays': goalDays};
    if (title != null) body['title'] = title;
    final json = await _post('/streak/shared', body);
    return json['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSharedStreak(String id) async {
    final json = await _get('/streak/shared/$id');
    return json['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinSharedStreak(String inviteCode) async {
    final json = await _post('/streak/shared/join', {'inviteCode': inviteCode});
    return json['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> leaveSharedStreak(String id) async {
    final json = await _post('/streak/shared/$id/leave', {});
    return json['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSharedStreakInvite(String code) async {
    final json = await _get('/streak/invite/$code');
    return json['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> shareStreak(String id) async {
    final json = await _get('/streak/shared/$id/share');
    return json['data'] as Map<String, dynamic>;
  }

  Future<void> revokeInvite(String id) async {
    await _post('/streak/shared/$id/revoke-invite', {});
  }

  // ---------- Account ----------

  Future<void> deleteAccount(AppState state) async {
    await http.delete(
      Uri.parse('$_base/auth/account'),
      headers: _headers(),
    ).timeout(const Duration(seconds: 15));
  }
}

