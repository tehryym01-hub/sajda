import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/share_image.dart';

class StreakShareCard extends StatefulWidget {
  final String? displayName;
  final StreakModel streak;
  final SharedStreakModel? sharedStreak;
  final List<StreakMemberModel> sharedMembers;

  const StreakShareCard({
    super.key,
    this.displayName,
    required this.streak,
    this.sharedStreak,
    this.sharedMembers = const [],
  });

  @override
  State<StreakShareCard> createState() => _StreakShareCardState();
}

class _StreakShareCardState extends State<StreakShareCard> {
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await shareWidgetAsImage(
        context: context,
        widget: _buildCard(),
        fileName: 'streak_share_${widget.streak.id}',
        caption: _buildShareText(),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _buildShareText() {
    final name = widget.displayName ?? 'Someone';
    final shared = widget.sharedStreak;
    final memberCount = widget.sharedMembers.where((m) => m.isActive).length;

    var text = '$name\'s Salah Streak\n\n';
    text += '${widget.streak.currentStreak} day streak active!\n';
    text += 'Best: ${widget.streak.longestStreak} days\n';
    text += 'Goal: ${widget.streak.goalDays} days\n';

    if (shared != null && memberCount > 0) {
      text += '\nPraying with $memberCount ${memberCount == 1 ? 'friend' : 'friends'}\n';
      final top3 = widget.sharedMembers.where((m) => m.isActive).toList()
        ..sort((a, b) => b.currentDay.compareTo(a.currentDay));
      for (var i = 0; i < top3.length && i < 3; i++) {
        text += '  ${top3[i].displayName} - ${top3[i].currentDay} days\n';
      }
    }

    text += '\nJoin me on Sajda: Daily Athan & Qibla\n';
    text += 'https://play.google.com/store/apps/details?id=com.sajda.dataplus';
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCard(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: _sharing ? null : _share,
            icon: _sharing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.ios_share_rounded, size: 20),
            label: Text(_sharing ? 'Preparing...' : 'Share Streak Card'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 420 ? 420.0 : screenWidth - 48;
    final shared = widget.sharedStreak;
    final activeMembers = widget.sharedMembers.where((m) => m.isActive).toList()
      ..sort((a, b) => b.currentDay.compareTo(a.currentDay));
    final memberCount = activeMembers.length;
    final topMembers = activeMembers.take(3).toList();

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A3D28), AppColors.primaryDeep, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -25,
                  left: -15,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mosque_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            'SAJDA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (widget.displayName != null && widget.displayName!.isNotEmpty)
                        Text(
                          widget.displayName!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 2),
                      Text(
                        'SALAH STREAK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatItem(
                            icon: Icons.local_fire_department_rounded,
                            value: '${widget.streak.currentStreak}',
                            label: 'Streak',
                          ),
                          Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15)),
                          _StatItem(
                            icon: Icons.emoji_events_rounded,
                            value: '${widget.streak.longestStreak}',
                            label: 'Best',
                          ),
                          Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15)),
                          _StatItem(
                            icon: Icons.flag_rounded,
                            value: '${widget.streak.goalDays}',
                            label: 'Goal',
                          ),
                          if (memberCount > 0) ...[
                            Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15)),
                            _StatItem(
                              icon: Icons.people_rounded,
                              value: '$memberCount',
                              label: 'Members',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (widget.streak.goalDays > 0 ? widget.streak.currentDay / widget.streak.goalDays : 0.0).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.streak.currentDay} / ${widget.streak.goalDays} days',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (shared != null && topMembers.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...topMembers.asMap().entries.map((entry) {
                                final i = entry.key;
                                final m = entry.value;
                                final medal = i == 0 ? '1st' : (i == 1 ? '2nd' : '3rd');
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      Text(
                                        medal,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          m.displayName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${m.currentDay}d',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_android_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Sajda: Daily Athan & Qibla',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
