import 'package:flutter_test/flutter_test.dart';
import 'package:sajda_dataplus/services/quran_translation_provider.dart';
import 'package:sajda_dataplus/services/tafsir_provider.dart';
import 'package:sajda_dataplus/services/quran_audio_provider.dart';

void main() {
  group('QuranTranslationProvider', () {
    test('initial state is unavailable', () {
      final provider = QuranTranslationProvider();
      expect(provider.state.availability, QuranTranslationAvailability.unavailable);
    });

    test('reset returns to unavailable', () {
      final provider = QuranTranslationProvider();
      provider.reset();
      expect(provider.state.availability, QuranTranslationAvailability.unavailable);
    });
  });

  group('TafsirProvider', () {
    test('initial state is unavailable', () {
      final provider = TafsirProvider();
      expect(provider.state.availability, TafsirAvailability.unavailable);
    });

    test('reset returns to unavailable', () {
      final provider = TafsirProvider();
      provider.reset();
      expect(provider.state.availability, TafsirAvailability.unavailable);
    });
  });

  group('QuranAudioProvider', () {
    test('initial state is unavailable', () {
      final provider = QuranAudioProvider();
      expect(provider.state.availability, QuranAudioAvailability.unavailable);
    });

    test('reset returns to unavailable', () {
      final provider = QuranAudioProvider();
      provider.reset();
      expect(provider.state.availability, QuranAudioAvailability.unavailable);
    });
  });
}
