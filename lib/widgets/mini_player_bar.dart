import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/audio_player_screen.dart';
import '../state/audio_player_state.dart';
import '../theme/app_theme.dart';

/// Global mini player bar shown above the bottom navigation while a surah
/// recitation or live Quran radio stream is active. Tapping it opens the
/// full player.
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerState>();
    if (!player.hasAudio) return const SizedBox.shrink();

    final surah = player.currentSurah;
    final station = player.radioStation;
    final title = surah != null
        ? '${surah.number}. ${surah.nameEn}'
        : (station?.name ?? '');
    final subtitle = surah != null ? player.reciterName : 'Quran Radio';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
      child: Material(
        color: AppColors.primaryDeep,
        elevation: 12,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AudioPlayerScreen()),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    player.isLive
                        ? Icons.radio_rounded
                        : Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (player.isLive) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      surah != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: player.duration == null ||
                                        player.duration!.inMilliseconds == 0
                                    ? null
                                    : player.position.inMilliseconds /
                                        player.duration!.inMilliseconds,
                                minHeight: 3,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary,
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                Icon(
                                  Icons.graphic_eq_rounded,
                                  size: 13,
                                  color: player.playing
                                      ? AppColors.primary
                                      : Colors.white38,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    subtitle,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: player.loading ? null : player.toggle,
                  icon: player.loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Icon(
                          player.playing
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          color: Colors.white,
                          size: 34,
                        ),
                ),
                IconButton(
                  onPressed: player.stop,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
