import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'invite_share_card.dart';

class SharedStreakBoardScreen extends StatelessWidget {
  const SharedStreakBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final shared = state.sharedStreak;
    final members = state.sharedMembers;

    if (shared == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(title: Text(state.t('Streak Board', 'سٹریک بورڈ'), style: const TextStyle(fontWeight: FontWeight.w800))),
        body: Center(
          child: Text(state.t('No shared streak', 'کوئی شیرڈ سٹریک نہیں')),
        ),
      );
    }

    final activeMembers = members.where((m) => m.isActive).toList()
      ..sort((a, b) => b.currentDay.compareTo(a.currentDay));
    final progress = shared.goalDays > 0 ? shared.currentDay / shared.goalDays : 0.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          shared.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${shared.currentDay}/${shared.goalDays} ${state.t('days', 'دن')}',
                              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${activeMembers.length} ${state.t('members', 'ممبران')}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () async {
                    final data = await state.shareStreak(shared.id);
                    if (data != null && context.mounted) {
                      final shareText = data['shareText']?.toString() ?? '';
                      final inviteUrl = data['inviteUrl']?.toString() ?? '';
                      final message = inviteUrl.isNotEmpty ? '$shareText\n\n$inviteUrl' : shareText;
                      if (message.isNotEmpty) {
                          await SharePlus.instance.share(ShareParams(text: message, subject: state.t('Join my Salah Streak', 'میرے صلاح سٹریک میں شامل ہوں')));
                      }
                    }
                  },
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => _showInviteDialog(context, state, shared),
                  icon: const Icon(Icons.group_add_rounded, color: Colors.white),
                ),
              ),
            ],
          ),

          // Podium (Top 3)
          if (activeMembers.length >= 2)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: _Podium(members: activeMembers, state: state),
              ),
            ),

          // Leaderboard List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primaryDeep.withValues(alpha: 0.05)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.leaderboard_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          state.t('Leaderboard', 'لیڈر بورڈ'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primaryDeep.withValues(alpha: 0.08)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            state.t('${shared.currentDay} day streak', '${shared.currentDay} دن کی سٹریک'),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(activeMembers.length, (i) {
                    final member = activeMembers[i];
                    return _LeaderboardTile(
                      rank: i + 1,
                      member: member,
                      goalDays: shared.goalDays,
                      isMe: member.userId == state.userId,
                      state: state,
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showInviteDialog(BuildContext context, AppState state, SharedStreakModel shared) async {
    final appUrl = 'https://sajdadailyathan.site';
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: InviteShareCard(
          streakTitle: shared.title,
          inviteCode: shared.inviteCode,
          appUrl: appUrl,
          creatorName: state.displayName,
        ),
      ),
    );
  }
}

// ─── Podium Widget ─────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<StreakMemberModel> members;
  final AppState state;

  const _Podium({required this.members, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top3 = members.take(3).toList();

    // Reorder: 2nd, 1st, 3rd for podium layout
    final ordered = <StreakMemberModel?>[];
    if (top3.length > 1) ordered.add(top3[1]);
    ordered.add(top3.isNotEmpty ? top3[0] : null);
    if (top3.length > 2) ordered.add(top3[2]);

    final heights = [100.0, 130.0, 80.0];
    final medalColors = [
      const Color(0xFFC0C0C0), // silver
      const Color(0xFFFFD700), // gold
      const Color(0xFFCD7F32), // bronze
    ];
    final medalIcons = [
      Icons.looks_one_rounded,
      Icons.emoji_events_rounded,
      Icons.looks_3_rounded,
    ];

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final member = ordered[i];
          if (member == null) return const SizedBox(width: 90);
          final height = heights[i];
          final medal = medalColors[i];
          final isMe = member.userId == state.userId;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [medal, medal.withValues(alpha: 0.8)],
                    ),
                    shape: BoxShape.circle,
                    border: isMe ? Border.all(color: Colors.white, width: 2.5) : null,
                    boxShadow: [
                      BoxShadow(color: medal.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  member.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isMe ? AppColors.primary : (isDark ? AppColors.darkText : AppColors.lightText),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${member.currentDay} ${state.t('days', 'دن')}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: medal,
                  ),
                ),
                const SizedBox(height: 6),
                // Podium bar
                Container(
                  height: height,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [medal.withValues(alpha: 0.35), medal.withValues(alpha: 0.15)],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    border: Border.all(color: medal.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Icon(
                      medalIcons[i],
                      size: 28,
                      color: medal,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Leaderboard Tile ──────────────────────────────────
class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final StreakMemberModel member;
  final int goalDays;
  final bool isMe;
  final AppState state;

  const _LeaderboardTile({
    required this.rank,
    required this.member,
    required this.goalDays,
    required this.isMe,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = goalDays > 0 ? member.currentDay / goalDays : 0.0;
    final today = DateTime.now();
    final lastDate = member.lastCompletedDate != null ? DateTime.tryParse(member.lastCompletedDate!) : null;
    final isTodayDone = lastDate != null &&
        lastDate.year == today.year &&
        lastDate.month == today.month &&
        lastDate.day == today.day;

    final medalColors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMe
              ? [AppColors.primary.withValues(alpha: 0.1), AppColors.primaryDeep.withValues(alpha: 0.05)]
              : [
                  isDark ? AppColors.darkSurface : AppColors.lightCard,
                  isDark ? AppColors.darkSurfaceAlt : AppColors.lightBackground,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: isMe
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: rank <= 3
                  ? LinearGradient(
                      colors: [medalColors[rank]!, medalColors[rank]!.withValues(alpha: 0.8)],
                    )
                  : null,
              color: rank <= 3 ? null : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightDivider),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      rank == 1 ? Icons.emoji_events_rounded : Icons.looks_3_rounded,
                      size: 18,
                      color: Colors.white,
                    )
                  : Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isDark ? AppColors.darkMuted : AppColors.lightMutedText,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: rank <= 3
                  ? LinearGradient(
                      colors: [medalColors[rank]!, medalColors[rank]!.withValues(alpha: 0.8)],
                    )
                  : LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDeep],
                    ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.displayName + (isMe ? ' (${state.t('You', 'آپ')})' : ''),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isMe ? AppColors.primary : (isDark ? AppColors.darkText : AppColors.lightText),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${member.currentDay} ${state.t('days', 'دن')}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.lightDivider,
                    valueColor: AlwaysStoppedAnimation(
                      rank <= 3 ? medalColors[rank]! : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isTodayDone ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      size: 12,
                      color: isTodayDone ? AppColors.primary : (isDark ? AppColors.darkMuted : AppColors.lightMutedText),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isTodayDone
                          ? state.t('Done today', 'آج مکمل')
                          : state.t('Pending', 'زیر التوا'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isTodayDone ? AppColors.primary : (isDark ? AppColors.darkMuted : AppColors.lightMutedText),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}





