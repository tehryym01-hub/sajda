import 'package:flutter/foundation.dart';

import '../services/api_client.dart';

enum QuranAudioAvailability { available, unavailable, error, loading }

class QuranAudioState {
  final QuranAudioAvailability availability;
  final String? url;
  final String? reciter;
  final String? message;

  const QuranAudioState._({
    required this.availability,
    this.url,
    this.reciter,
    this.message,
  });

  const QuranAudioState.unavailable([String? message])
      : this._(
          availability: QuranAudioAvailability.unavailable,
          message: message,
        );

  const QuranAudioState.available({
    String? url,
    String? reciter,
  }) : this._(
          availability: QuranAudioAvailability.available,
          url: url,
          reciter: reciter,
        );

  const QuranAudioState.error(String? message)
      : this._(
          availability: QuranAudioAvailability.error,
          message: message,
        );

  bool get isAvailable => availability == QuranAudioAvailability.available;
}

class QuranAudioProvider extends ChangeNotifier {
  QuranAudioState _state = const QuranAudioState.unavailable(
    'Audio temporarily unavailable',
  );

  QuranAudioState get state => _state;

  Future<void> loadSurahAudio(int surah, String reciter) async {
    _state = const QuranAudioState.unavailable('Loading audio...');
    notifyListeners();

    try {
      final api = ApiClient.instance;
      final res = await api.get(
        '/quran/audio/surah/$surah?reciter=${Uri.encodeQueryComponent(reciter)}',
      );
      final data = res['data'];
      String? audioUrl;

      if (data is List && data.isNotEmpty) {
        final first = data.first as Map<String, dynamic>?;
        audioUrl = first?['audioUrl']?.toString() ??
            first?['audio_url']?.toString() ??
            first?['url']?.toString() ??
            first?['audio']?.toString();
      } else if (data is Map) {
        audioUrl = data['audioUrl']?.toString() ??
            data['audio_url']?.toString() ??
            data['url']?.toString() ??
            data['audio']?.toString();
      }

      if (audioUrl != null && audioUrl.isNotEmpty) {
        _state = QuranAudioState.available(
          url: audioUrl,
          reciter: reciter,
        );
      } else {
        _state = const QuranAudioState.unavailable(
          'Audio not available for this surah',
        );
      }
    } catch (e) {
      _state = QuranAudioState.error(
        'Failed to load audio. Please check your connection and try again.',
      );
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _state = const QuranAudioState.unavailable('Audio temporarily unavailable');
    notifyListeners();
  }
}
