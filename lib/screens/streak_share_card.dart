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

    var text = '🔥 $name\'s Salah Streak\n\n';
    text += '📅 ${widget.streak.currentStreak} day streak active!\n';
    text += '🏆 Best: ${widget.streak.longestStreak} days\n';
    text += '🎯 Goal: ${widget.streak.goalDays} days\n';

    if (shared != null && memberCount > 0) {
      text += '\n👥 Praying with $memberCount ${memberCount == 1 ? 'friend' : 'friends'}\n';
      final top3 = widget.sharedMembers.where((m) => m.isActive).toList()
        ..sort((a, b) => b.currentDay.compareTo(a.currentDay));
      for (var i = 0; i < top3.length && i < 3; i++) {
        text += '  ${i == 1 ? '🥇' : (i == 2 ? '🥈' : '🥉')} ${top3[i].displayName} - ${top3[i].currentDay} days\n';
      }
    }

    text += '\n📲 Join me on Sajda: Daily Athan & Qibla\n';
    text += '🔗 https://sajdadailyathan.site';
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCard(),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _sharing ? null : _share,
            icon: _sharing
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.ios_share_rounded),
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -30,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🔥', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 8),
                            Text(
                              'SAJDA',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (widget.displayName != null && widget.displayName!.isNotEmpty) ...[
                        Text(
                          '${widget.displayName}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SALAH STREAK',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        Text(
                          'SALAH STREAK',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${widget.streak.currentStreak}',
                              style: const TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'DAY STREAK',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(
                            icon: Icons.emoji_events_rounded,
                            value: '${widget.streak.longestStreak}',
                            label: 'Best',
                          ),
                          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.15)),
                          _StatItem(
                            icon: Icons.flag_rounded,
                            value: '${widget.streak.goalDays}',
                            label: 'Goal',
                          ),
                          if (memberCount > 0) ...[
                            Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.15)),
                            _StatItem(
                              icon: Icons.people_rounded,
                              value: '$memberCount',
                              label: 'Members',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (widget.streak.goalDays > 0 ? widget.streak.currentDay / widget.streak.goalDays : 0.0).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.streak.currentDay} / ${widget.streak.goalDays} days completed',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (shared != null && topMembers.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.people_rounded, color: AppColors.primary, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PRAYING TOGETHER',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...topMembers.asMap().entries.map((entry) {
                                final i = entry.key;
                                final m = entry.value;
                                final medal = i == 0 ? '🥇' : (i == 1 ? '🥈' : '🥉');
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    children: [
                                      Text(medal, style: const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          m.displayName,
                                          style: const TextStyle(
                                            fontSize: 13,
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
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              if (memberCount > 3)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '+${memberCount - 3} more',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDeep],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Join me on SAJDA',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_android_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'Sajda: Daily Athan & Qibla',
                              style: TextStyle(
                                fontSize: 12,
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
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}







