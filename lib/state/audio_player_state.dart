import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../services/quran_service.dart';

class AudioPlayerState extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  SurahInfo? currentSurah;
  String reciterCode =
      QuranService.reciters.isNotEmpty ? QuranService.reciters.first.code : '';
  String reciterName =
      QuranService.reciters.isNotEmpty ? QuranService.reciters.first.name : '';
  String? streamUrl;
  String? streamTitle;
  String? streamSubtitle;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration? _duration;

  bool get playing => _playing;
  Duration get position => _position;
  Duration? get duration => _duration;
  bool get hasAudio => currentSurah != null || streamUrl != null;

  Future<void> playStream(String title, String subtitle, String url) async {
    streamUrl = url;
    streamTitle = title;
    streamSubtitle = subtitle;
    currentSurah = null;
    notifyListeners();
    try {
      await _player.stop();
      await _player.setUrl(url);
      await _player.setLoopMode(LoopMode.one);
      await _player.play();
    } catch (_) {
      streamUrl = null;
      notifyListeners();
    }
  }

  AudioPlayerState() {
    _stateSub = _player.playerStateStream.listen((state) {
      final next = state.playing;
      if (next != _playing) {
        _playing = next;
        notifyListeners();
      }
    });
    _positionSub = _player.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });
    _durationSub = _player.durationStream.listen((d) {
      _duration = d;
      notifyListeners();
    });
  }

  Future<void> playSurah(SurahInfo surah, String code, String name) async {
    currentSurah = surah;
    reciterCode = code;
    reciterName = name;
    streamUrl = null;
    streamTitle = null;
    streamSubtitle = null;
    notifyListeners();
    try {
      await _player.stop();
      await _player.setUrl(
        QuranService.instance.surahAudioUrl(surah.number, code),
      );
      await _player.setLoopMode(LoopMode.one);
      await _player.play();
    } catch (_) {
      currentSurah = null;
      notifyListeners();
    }
  }

  Future<void> playVerse(int surah, int ayah) async {
    try {
      await _player.stop();
      streamUrl = null;
      streamTitle = null;
      streamSubtitle = null;
      await _player.setUrl(
        QuranService.instance.verseAudioUrl(surah, ayah, reciterCode),
      );
      await _player.play();
    } catch (_) {}
  }

  Future<void> toggle() async {
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    currentSurah = null;
    streamUrl = null;
    streamTitle = null;
    streamSubtitle = null;
    _duration = null;
    notifyListeners();
  }

  Future<void> seek(Duration d) async {
    await _player.seek(d);
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
