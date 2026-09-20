import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Connects just_audio to audio_service so playback survives backgrounding
/// and surfaces play/pause/seek/next/previous controls in the Android media
/// notification and on the lock screen.
class SajdaAudioHandler extends BaseAudioHandler {
  final AudioPlayer player = AudioPlayer();

  /// True while a live radio stream (no seek/next/previous) is loaded.
  bool liveMode = false;

  SajdaAudioHandler() {
    player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() =>
      liveMode ? Future.value() : player.seekToNext();

  @override
  Future<void> skipToPrevious() =>
      liveMode ? Future.value() : player.seekToPrevious();

  /// Loads a verse-by-verse surah playlist (gapless) and starts playback.
  Future<void> playSurahSources(
    List<AudioSource> sources, {
    int initialIndex = 0,
  }) async {
    liveMode = false;
    await player.stop();
    await player.setAudioSources(sources, initialIndex: initialIndex);
    await player.play();
  }

  /// Loads a single ayah clip.
  Future<void> playSingleSource(AudioSource source) async {
    liveMode = false;
    await player.stop();
    await player.setAudioSource(source);
    await player.play();
  }

  /// Loads a live Icecast radio stream.
  Future<void> playLiveUrl(String url) async {
    liveMode = true;
    await player.stop();
    await player.setAudioSource(AudioSource.uri(Uri.parse(url)));
    await player.play();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    final controls = liveMode
        ? [
            if (player.playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
          ]
        : [
            MediaControl.skipToPrevious,
            if (player.playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.stop,
          ];
    return PlaybackState(
      controls: controls,
      systemActions: liveMode
          ? const {MediaAction.seek, MediaAction.stop}
          : const {
              MediaAction.seek,
              MediaAction.seekForward,
              MediaAction.seekBackward,
              MediaAction.skipToNext,
              MediaAction.skipToPrevious,
            },
      androidCompactActionIndices:
          liveMode ? const [0] : const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
    );
  }
}
