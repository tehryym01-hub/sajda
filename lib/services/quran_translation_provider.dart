import 'package:flutter/foundation.dart';

import '../services/api_client.dart';

enum QuranTranslationAvailability { available, unavailable, error, loading }

class QuranTranslationState {
  final QuranTranslationAvailability availability;
  final Map<int, String> translations;
  final String? source;
  final String? message;

  const QuranTranslationState._({
    required this.availability,
    this.translations = const {},
    this.source,
    this.message,
  });

  const QuranTranslationState.unavailable([String? message])
      : this._(
          availability: QuranTranslationAvailability.unavailable,
          message: message,
        );

  const QuranTranslationState.available({
    Map<int, String>? translations,
    String? source,
  }) : this._(
          availability: QuranTranslationAvailability.available,
          translations: translations ?? const {},
          source: source,
        );

  const QuranTranslationState.error(String? message)
      : this._(
          availability: QuranTranslationAvailability.error,
          message: message,
        );

  bool get isAvailable => availability == QuranTranslationAvailability.available;
}

class QuranTranslationProvider extends ChangeNotifier {
  QuranTranslationState _state = const QuranTranslationState.unavailable(
    'Translation temporarily unavailable',
  );

  QuranTranslationState get state => _state;

  Future<void> loadSurahTranslations(int surah) async {
    _state = const QuranTranslationState.unavailable('Loading translations...');
    notifyListeners();

    try {
      final api = ApiClient.instance;
      final res = await api.get('/quran/surah/$surah/translations');
      final data = res['data'];
      final translations = <int, String>{};

      if (data is Map && data['verses'] is List) {
        final verses = data['verses'] as List;
        for (final verse in verses) {
          if (verse is Map<String, dynamic>) {
            final verseNumber = verse['verse_number'] ?? verse['verseNumber'];
            final translation = _extractTranslation(verse);
            if (verseNumber != null && translation != null) {
              translations[verseNumber] = translation;
            }
          }
        }
      } else if (data is Map && data['verse'] is Map) {
        final verse = data['verse'] as Map<String, dynamic>;
        final verseNumber = verse['verse_number'] ?? verse['verseNumber'];
        final translation = _extractTranslation(verse);
        if (verseNumber != null && translation != null) {
          translations[verseNumber] = translation;
        }
      }

      if (translations.isNotEmpty) {
        _state = QuranTranslationState.available(translations: translations);
      } else {
        _state = const QuranTranslationState.unavailable(
          'Translations not available for this surah',
        );
      }
    } catch (e) {
      _state = QuranTranslationState.error(
        'Failed to load translations. Please check your connection and try again.',
      );
    } finally {
      notifyListeners();
    }
  }

  String? _extractTranslation(Map<String, dynamic> verse) {
    final translations = verse['translations'];
    if (translations is List && translations.isNotEmpty) {
      return translations.first['text']?.toString();
    }
    return null;
  }

  void reset() {
    _state = const QuranTranslationState.unavailable(
      'Translation temporarily unavailable',
    );
    notifyListeners();
  }
}
