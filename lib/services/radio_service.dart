import 'dart:convert';

import 'package:http/http.dart' as http;

/// A live Quran radio station from the MP3Quran.net radio API
/// (Icecast streams, freely broadcast for public listening).
class RadioStation {
  final String id;
  final String name;
  final String url;
  const RadioStation({
    required this.id,
    required this.name,
    required this.url,
  });
}

/// Fetches live Quran radio stations from MP3Quran.net.
///
/// Endpoint: https://mp3quran.net/api/radio/radio_en.json
/// Response shape: {"Radios": [{"Id": "...", "Name": "...", "URL": "..."}]}
class RadioService {
  static final RadioService instance = RadioService._();
  RadioService._();

  static const _endpoint =
      'https://mp3quran.net/api/radio/radio_en.json';
  static const _timeout = Duration(seconds: 20);

  List<RadioStation>? _cached;
  Future<List<RadioStation>>? _inFlight;

  List<RadioStation>? get cachedStations => _cached;

  Future<List<RadioStation>> getStations({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached!;
    final existing = _inFlight;
    if (existing != null) return existing;
    final future = _fetch();
    _inFlight = future;
    try {
      final stations = await future;
      _cached = stations;
      return stations;
    } finally {
      _inFlight = null;
    }
  }

  Future<List<RadioStation>> _fetch() async {
    try {
      final res = await http.get(Uri.parse(_endpoint)).timeout(_timeout);
      if (res.statusCode != 200) {
        throw Exception('status ${res.statusCode}');
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      final radios = body['Radios'];
      if (radios is! List) throw Exception('bad shape');

      final stations = <RadioStation>[];
      final seen = <String>{};
      for (final r in radios) {
        if (r is! Map) continue;
        final url = (r['URL'] ?? r['url'])?.toString() ?? '';
        if (!url.startsWith('https://')) continue;
        final name = (r['Name'] ?? r['name'])?.toString().trim() ?? '';
        if (name.isEmpty || !seen.add(url)) continue;
        stations.add(RadioStation(
          id: (r['Id'] ?? r['id'])?.toString() ?? url,
          name: name,
          url: url,
        ));
      }
      if (stations.isEmpty) throw Exception('empty');
      stations.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return stations;
    } catch (_) {
      throw const RadioApiException(
        'Could not load radio stations. Please check your connection and try again.',
      );
    }
  }
}

class RadioApiException implements Exception {
  final String message;
  const RadioApiException(this.message);
  @override
  String toString() => message;
}
