import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../models/azkar_model.dart';
import '../services/azkar_audio_provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class ZikrDetailScreen extends StatefulWidget {
  final ZikrCategory category;
  const ZikrDetailScreen({super.key, required this.category});

  @override
  State<ZikrDetailScreen> createState() => _ZikrDetailScreenState();
}

class _ZikrDetailScreenState extends State<ZikrDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  final Map<int, int> _counts = {};
  bool _playing = false;
  bool _loadingAudio = false;

  ZikrCategory get _category => widget.category;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (mounted && state.playing != _playing) {
        setState(() => _playing = state.playing);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(AzkarAudioProvider audioProvider) async {
    if (_playing) {
      await _player.stop();
      return;
    }

    final audioState = audioProvider.state;
    if (audioState.availability != AzkarAudioAvailability.available) {
      if (!mounted) return;
      showAppSnack(
        context,
        audioState.message ?? 'Audio temporarily unavailable',
        error: true,
      );
      return;
    }

    final url = audioState.licensedUrl;
    if (url == null || url.isEmpty) {
      if (!mounted) return;
      showAppSnack(context, 'Audio temporarily unavailable', error: true);
      return;
    }

    setState(() => _loadingAudio = true);
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, 'Could not play audio', error: true);
    }
    if (mounted) setState(() => _loadingAudio = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final audioProvider = context.watch<AzkarAudioProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_category.category, style: const TextStyle(fontFamily: 'serif')),
        actions: [
          IconButton(
            onPressed: audioProvider.isAvailable
                ? () => _toggleAudio(audioProvider)
                : null,
            icon: _loadingAudio
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(_playing ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded),
            tooltip: audioProvider.isAvailable
                ? state.t('Play audio', 'آڈیو سنیں')
                : state.t('Audio temporarily unavailable', 'آڈیو عارضی طور پر دستیاب نہیں'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _category.items.length,
        itemBuilder: (ctx, i) {
          final item = _category.items[i];
          final done = _counts[item.id] ?? 0;
          final complete = done >= item.count;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              border: complete ? Border.all(color: AppColors.primary, width: 1.5) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 16.5,
                      height: 1.8,
                      fontFamily: 'serif',
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkText
                          : const Color(0xFF12352B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => setState(() {
                          _counts[item.id] = done >= item.count ? 0 : done + 1;
                        }),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: complete ? AppColors.primary : AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            complete
                                ? state.t('Completed ✓', 'مکمل ✓')
                                : '$done / ${item.count}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        state.t('Tap to count', 'گننے کے لیے تھپتھپائیں'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
