import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/audio_player_state.dart';
import '../theme/app_theme.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerState>();
    final surah = player.currentSurah;
    if (surah == null && player.streamUrl == null) {
      return const SizedBox.shrink();
    }
    final duration = player.duration ?? Duration.zero;
    final position =
        duration.inSeconds == 0 ? 0.0 : player.position.inSeconds / duration.inSeconds;
    final title = surah != null
        ? '${surah.number}. ${surah.nameEn}'
        : (player.streamTitle ?? '');
    final subtitle = surah != null
        ? player.reciterName.split(' ').first
        : (player.streamSubtitle ?? '');

    return Material(
      color: AppColors.primaryDeep,
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Color(0xFF04241C)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: position,
                            minHeight: 3,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: player.toggle,
              icon: Icon(
                player.playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: Colors.white,
                size: 34,
              ),
            ),
            IconButton(
              onPressed: player.stop,
              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}