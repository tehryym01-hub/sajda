import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// One surah's verse-by-verse recitation, streamed as a gapless playlist.
class SurahRecitation {
  final int number;
  final String nameEn;
  final String nameAr;
  final List<String> ayahUrls;
  const SurahRecitation({
    required this.number,
    required this.nameEn,
    required this.nameAr,
    required this.ayahUrls,
  });
}

class AudioApiException implements Exception {
  final String message;
  const AudioApiException(this.message);
  @override
  String toString() => message;
}

/// Fetches surah-wise audio recitations from the Al Quran Cloud API
/// (https://api.alquran.cloud/v1/quran/{reciter}).
///
/// All recitations are hosted on the islamic.network CDN, which distributes
/// them freely for public use (copyright-free).
class QuranAudioService {
  static final QuranAudioService instance = QuranAudioService._();
  QuranAudioService._();

  static const _baseUrl = 'https://api.alquran.cloud/v1/quran';
  static const _timeout = Duration(seconds: 30);

  final _memory = <String, Map<int, SurahRecitation>>{};
  final _inFlight = <String, Future<Map<int, SurahRecitation>>>{};

  /// Full recitation index for [reciterCode] (e.g. `ar.alafasy`).
  /// Memory -> disk cache -> network, in that order.
  Future<Map<int, SurahRecitation>> getRecitations(
    String reciterCode, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _memory[reciterCode];
      if (cached != null) return cached;
    }

    final existing = _inFlight[reciterCode];
    if (existing != null) return existing;

    final future = _load(reciterCode, forceRefresh);
    _inFlight[reciterCode] = future;
    try {
      final result = await future;
      _memory[reciterCode] = result;
      return result;
    } finally {
      _inFlight.remove(reciterCode);
    }
  }

  Future<SurahRecitation?> getSurah(int surahNumber, String reciterCode) async {
    final all = await getRecitations(reciterCode);
    return all[surahNumber];
  }

  Future<Map<int, SurahRecitation>> _load(
    String reciterCode,
    bool forceRefresh,
  ) async {
    if (!forceRefresh) {
      final disk = await _readDiskCache(reciterCode);
      if (disk != null) return disk;
    }

    final Map<int, SurahRecitation> parsed;
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/$reciterCode'))
          .timeout(_timeout);
      if (res.statusCode != 200) {
        throw AudioApiException(
          'Recitation service unavailable (${res.statusCode})',
        );
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body['code'] != 200 || body['data'] == null) {
        throw const AudioApiException('Unexpected response from recitation service');
      }
      parsed = _parse(body['data']);
    } on AudioApiException {
      rethrow;
    } catch (_) {
      throw const AudioApiException(
        'Could not load recitations. Please check your connection and try again.',
      );
    }

    if (parsed.isEmpty) {
      throw const AudioApiException('No recitations available right now');
    }
    await _writeDiskCache(reciterCode, parsed);
    return parsed;
  }

  Map<int, SurahRecitation> _parse(dynamic data) {
    final surahs = data['surahs'];
    if (surahs is! List) return const {};
    final result = <int, SurahRecitation>{};
    for (final s in surahs) {
      if (s is! Map) continue;
      final number = s['number'];
      final ayahs = s['ayahs'];
      if (number is! int || ayahs is! List) continue;
      final urls = <String>[];
      for (final a in ayahs) {
        if (a is! Map) continue;
        final url = a['audio']?.toString();
        if (url != null && url.startsWith('https://')) urls.add(url);
      }
      if (urls.isEmpty) continue;
      result[number] = SurahRecitation(
        number: number,
        nameEn: s['englishName']?.toString() ?? 'Surah $number',
        nameAr: s['name']?.toString() ?? '',
        ayahUrls: urls,
      );
    }
    return result;
  }

  // ---------- Disk cache (compact: surah -> ayah URLs) ----------

  Future<String> _cacheFile(String reciterCode) async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}${Platform.pathSeparator}quran_audio_'
        '${reciterCode.replaceAll('.', '_')}.json';
  }

  Future<Map<int, SurahRecitation>?> _readDiskCache(String reciterCode) async {
    try {
      final file = File(await _cacheFile(reciterCode));
      if (!await file.exists()) return null;
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map) return null;
      final result = <int, SurahRecitation>{};
      raw.forEach((key, value) {
        final number = int.tryParse(key.toString());
        if (number == null || value is! List) return;
        final urls = value
            .whereType<String>()
            .where((u) => u.startsWith('https://'))
            .toList(growable: false);
        if (urls.isEmpty) return;
        result[number] = SurahRecitation(
          number: number,
          nameEn: 'Surah $number',
          nameAr: '',
          ayahUrls: urls,
        );
      });
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDiskCache(
    String reciterCode,
    Map<int, SurahRecitation> recitations,
  ) async {
    try {
      final file = File(await _cacheFile(reciterCode));
      final compact = <String, List<String>>{};
      recitations.forEach(
        (k, v) => compact['$k'] = v.ayahUrls,
      );
      await file.writeAsString(jsonEncode(compact), flush: true);
    } catch (_) {}
  }

  /// Removes every cached recitation index (used when storage is corrupted
  /// or the user wants a fresh fetch).
  Future<void> clearCache() async {
    _memory.clear();
    try {
      final dir = await getApplicationSupportDirectory();
      await for (final entity in dir.list()) {
        final name = entity.uri.pathSegments.last;
        if (entity is File && name.startsWith('quran_audio_')) {
          await entity.delete();
        }
      }
    } catch (_) {}
  }
}
