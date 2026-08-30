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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (shared == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(title: Text(state.t('Streak Board', 'سٹریک بورڈ'), style: const TextStyle(fontWeight: FontWeight.w800))),
        body: Center(child: Text(state.t('No shared streak', 'کوئی شیرڈ سٹریک نہیں'))),
      );
    }

    final activeMembers = members.where((m) => m.isActive).toList()
      ..sort((a, b) => b.currentDay.compareTo(a.currentDay));
    final progress = shared.goalDays > 0 ? shared.currentDay / shared.goalDays : 0.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.primaryDeep,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D6B3F), AppColors.primaryDeep, Color(0xFF063A20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                          ),
                          child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          shared.title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${shared.currentDay} / ${shared.goalDays} ${state.t('days', 'دن')}',
                              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${activeMembers.length} ${state.t('members', 'ممبران')}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
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
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
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
                  icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => _showInviteDialog(context, state, shared),
                  icon: const Icon(Icons.group_add_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),

          // Podium
          if (activeMembers.length >= 2)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: _Podium(members: activeMembers, state: state),
              ),
            ),

          // Leaderboard header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.leaderboard_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    state.t('Leaderboard', 'لیڈر بورڈ'),
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? AppColors.darkText : AppColors.lightText),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.t('${shared.currentDay}d streak', '${shared.currentDay}دن'),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Leaderboard list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.separated(
              itemCount: activeMembers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final member = activeMembers[i];
                return _LeaderboardTile(
                  rank: i + 1,
                  member: member,
                  goalDays: shared.goalDays,
                  isMe: member.userId == state.userId,
                  state: state,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showInviteDialog(BuildContext context, AppState state, SharedStreakModel shared) async {
    final appUrl = 'https://play.google.com/store/apps/details?id=com.sajda.dataplus';
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

// ─── Compact Podium ─────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<StreakMemberModel> members;
  final AppState state;

  const _Podium({required this.members, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top3 = members.take(3).toList();

    final ordered = <StreakMemberModel?>[];
    if (top3.length > 1) ordered.add(top3[1]);
    ordered.add(top3.isNotEmpty ? top3[0] : null);
    if (top3.length > 2) ordered.add(top3[2]);
    while (ordered.length < 3) ordered.add(null);

    final barHeights = [44.0, 60.0, 34.0];
    final medalColors = [
      const Color(0xFFC0C0C0),
      const Color(0xFFFFD700),
      const Color(0xFFCD7F32),
    ];
    final medalLabels = ['2nd', '1st', '3rd'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final member = ordered[i];
            final medal = medalColors[i];
            final barH = barHeights[i];

            if (member == null) {
              return Expanded(
                child: SizedBox(
                  height: 140,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline_rounded, size: 32, color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 4),
                        Text(
                          state.t('Empty', 'خالی'),
                          style: TextStyle(fontSize: 10, color: Colors.grey.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final isMe = member.userId == state.userId;

            return Expanded(
              child: SizedBox(
                height: 140,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Medal label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: medal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        medalLabels[i],
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: medal),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Avatar
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [medal, medal.withValues(alpha: 0.7)]),
                        shape: BoxShape.circle,
                        border: isMe ? Border.all(color: Colors.white, width: 2) : null,
                        boxShadow: [BoxShadow(color: medal.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Center(
                        child: Text(
                          member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Name
                    SizedBox(
                      width: 80,
                      child: Text(
                        member.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isMe ? AppColors.primary : (isDark ? AppColors.darkText : AppColors.lightText),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Days
                    Text(
                      '${member.currentDay} ${state.t('days', 'دن')}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: medal),
                    ),
                    const Spacer(),
                    // Bar
                    Container(
                      height: barH,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [medal.withValues(alpha: 0.3), medal.withValues(alpha: 0.08)],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        border: Border.all(color: medal.withValues(alpha: 0.3)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
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
    final rankColor = medalColors[rank];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withValues(alpha: 0.08)
            : (isDark ? AppColors.darkSurface : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: rankColor != null
                  ? LinearGradient(colors: [rankColor, rankColor.withValues(alpha: 0.7)])
                  : null,
              color: rankColor == null ? (isDark ? AppColors.darkSurfaceAlt : AppColors.lightDivider) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: rankColor != null
                  ? Text(
                      '$rank',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white),
                    )
                  : Text(
                      '$rank',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.lightMutedText),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: rankColor != null
                  ? LinearGradient(colors: [rankColor, rankColor.withValues(alpha: 0.7)])
                  : LinearGradient(colors: [AppColors.primary, AppColors.primaryDeep]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 10),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isMe ? AppColors.primary : (isDark ? AppColors.darkText : AppColors.lightText),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${member.currentDay}d',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: rankColor ?? (isDark ? AppColors.darkText : AppColors.lightText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.lightDivider,
                    valueColor: AlwaysStoppedAnimation(rankColor ?? AppColors.primary),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      isTodayDone ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      size: 11,
                      color: isTodayDone ? AppColors.primary : (isDark ? AppColors.darkMuted : AppColors.lightMutedText),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isTodayDone ? state.t('Done', 'مکمل') : state.t('Pending', 'زیر التوا'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
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
