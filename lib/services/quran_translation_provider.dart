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

  /// Successful results are kept per surah+lang so re-opening the screen or
  /// toggling tabs never refetches.
  final Map<String, QuranTranslationState> _cache = {};

  QuranTranslationState? cachedFor(int surah, String lang) =>
      _cache['$surah:$lang'];

  Future<void> loadSurahTranslations(int surah, {String lang = 'ur'}) async {
    final cached = _cache['$surah:$lang'];
    if (cached != null) {
      _state = cached;
      notifyListeners();
      return;
    }

    _state = const QuranTranslationState.unavailable('Loading translations...');
    notifyListeners();

    try {
      final api = ApiClient.instance;
      final res =
          await api.get('/quran/surah/$surah/translations?lang=$lang');
      final data = res['data'];
      final translations = <int, String>{};
      String? source;

      if (data is Map && data['verses'] is List) {
        source = data['translation_name']?.toString();
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
        _state = QuranTranslationState.available(
          translations: translations,
          source: source,
        );
        _cache['$surah:$lang'] = _state;
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
    _cache.clear();
    _state = const QuranTranslationState.unavailable(
      'Translation temporarily unavailable',
    );
    notifyListeners();
  }
}
