import 'package:flutter/foundation.dart';

enum AzkarAudioAvailability { available, unavailable, error }

class AzkarAudioState {
  final AzkarAudioAvailability availability;
  final String? message;
  final String? licensedUrl;

  const AzkarAudioState._({
    required this.availability,
    this.message,
    this.licensedUrl,
  });

  const AzkarAudioState.unavailable([String? message])
      : this._(
          availability: AzkarAudioAvailability.unavailable,
          message: message ?? 'Audio temporarily unavailable',
        );

  const AzkarAudioState.available(String? url)
      : this._(
          availability: AzkarAudioAvailability.available,
          licensedUrl: url,
        );

  const AzkarAudioState.error(String? message)
      : this._(
          availability: AzkarAudioAvailability.error,
          message: message,
        );
}

class AzkarAudioProvider extends ChangeNotifier {
  AzkarAudioState _state = const AzkarAudioState.unavailable();

  AzkarAudioState get state => _state;

  bool get isAvailable => _state.availability == AzkarAudioAvailability.available;

  Future<void> load(String categoryId, String? audioUrl) async {
    if (audioUrl == null || audioUrl.trim().isEmpty) {
      _state = const AzkarAudioState.unavailable();
      notifyListeners();
      return;
    }

    _state = const AzkarAudioState.unavailable('Audio temporarily unavailable');
    notifyListeners();
  }

  void reset() {
    _state = const AzkarAudioState.unavailable();
    notifyListeners();
  }
}
