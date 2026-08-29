import 'package:flutter/foundation.dart';

import '../services/api_client.dart';

enum TafsirAvailability { available, unavailable, error, loading }

class TafsirState {
  final TafsirAvailability availability;
  final Map<int, String> tafsirs;
  final String? source;
  final String? message;

  const TafsirState._({
    required this.availability,
    this.tafsirs = const {},
    this.source,
    this.message,
  });

  const TafsirState.unavailable([String? message])
      : this._(
          availability: TafsirAvailability.unavailable,
          message: message,
        );

  const TafsirState.available({
    Map<int, String>? tafsirs,
    String? source,
  }) : this._(
          availability: TafsirAvailability.available,
          tafsirs: tafsirs ?? const {},
          source: source,
        );

  const TafsirState.error(String? message)
      : this._(
          availability: TafsirAvailability.error,
          message: message,
        );

  bool get isAvailable => availability == TafsirAvailability.available;
}

class TafsirProvider extends ChangeNotifier {
  TafsirState _state = const TafsirState.unavailable(
    'Tafsir temporarily unavailable',
  );

  TafsirState get state => _state;

  Future<void> loadSurahTafsir(int surah) async {
    _state = const TafsirState.unavailable('Loading tafsir...');
    notifyListeners();

    try {
      final api = ApiClient.instance;
      final res = await api.get('/quran/surah/$surah/tafsir');
      final data = res['data'];
      final tafsirs = <int, String>{};

      if (data is List) {
        for (final verse in data) {
          if (verse is Map<String, dynamic>) {
            final verseNumber = verse['verse_number'] ?? verse['verseNumber'];
            final tafsirText = _extractTafsir(verse);
            if (verseNumber != null && tafsirText != null) {
              tafsirs[verseNumber] = tafsirText;
            }
          }
        }
      } else if (data is Map && data['verses'] is List) {
        final verses = data['verses'] as List;
        for (final verse in verses) {
          if (verse is Map<String, dynamic>) {
            final verseNumber = verse['verse_number'] ?? verse['verseNumber'];
            final tafsirText = _extractTafsir(verse);
            if (verseNumber != null && tafsirText != null) {
              tafsirs[verseNumber] = tafsirText;
            }
          }
        }
      }

      if (tafsirs.isNotEmpty) {
        _state = TafsirState.available(tafsirs: tafsirs);
      } else {
        _state = const TafsirState.unavailable(
          'Tafsir not available for this surah',
        );
      }
    } catch (e) {
      _state = TafsirState.error(
        'Failed to load tafsir. Please check your connection and try again.',
      );
    } finally {
      notifyListeners();
    }
  }

  String? _extractTafsir(Map<String, dynamic> verse) {
    final tafsirs = verse['tafsirs'];
    if (tafsirs is List && tafsirs.isNotEmpty) {
      return tafsirs.first['text']?.toString();
    }
    return null;
  }

  void reset() {
    _state = const TafsirState.unavailable('Tafsir temporarily unavailable');
    notifyListeners();
  }
}
