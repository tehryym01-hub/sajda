import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'invite_share_card.dart';
import 'shared_streak_board_screen.dart';
import 'create_streak_screen.dart';
import 'join_streak_screen.dart';

class MyStreakScreen extends StatelessWidget {
  const MyStreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = state.streak;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: streak == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primaryDeep.withValues(alpha: 0.1)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(Icons.local_fire_department_outlined, size: 56, color: AppColors.primary.withValues(alpha: 0.8)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      state.t('No streak yet', 'ابھی تک کوئی سٹریک نہیں'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDeep],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const CreateStreakScreen()),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, color: Colors.white),
                        label: Text(state.t('Start a Streak', 'سٹریک شروع کریں'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 240,
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
                          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${streak.currentStreak}',
                                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                              ),
                              Text(
                                state.t('Current Streak', 'موجودہ سٹریک'),
                                style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${streak.currentDay}/${streak.goalDays} ${state.t('days', 'دن')}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                ),
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
                          final data = await state.shareStreak(streak.id);
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
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _InfoTile(
                                icon: Icons.emoji_events_rounded,
                                label: state.t('Best Streak', 'بہترین سٹریک'),
                                value: '${streak.longestStreak} ${state.t('days', 'دن')}',
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _InfoTile(
                                icon: streak.status == 'active' ? Icons.play_circle_rounded : Icons.pause_circle_rounded,
                                label: state.t('Status', 'حیثیت'),
                                value: streak.status == 'active' ? state.t('Active', 'فعال') : (streak.status == 'paused' ? state.t('Paused', 'روک دیا') : streak.status),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _SectionHeader(
                          icon: Icons.today_rounded,
                          title: state.t('Today\'s Salah', 'آج کی نماز'),
                          trailing: Text(
                            state.t('Keep going 🤍', 'جاری رکھیں 🤍'),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _TodayPrayerList(),
                        const SizedBox(height: 24),
                        _SectionHeader(icon: Icons.calendar_view_week_rounded, title: state.t('This Week', 'اس ہفتے')),
                        const SizedBox(height: 12),
                        const _WeekView(),
                        const SizedBox(height: 24),
                        if (streak.isShared && state.sharedStreak != null) ...[
                          _SectionHeader(
                            icon: Icons.leaderboard_rounded,
                            title: state.t('Shared Streak', 'شیر شد سٹریک'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.primary, AppColors.primaryDeep],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const SharedStreakBoardScreen()),
                                      );
                                    },
                                    icon: const Icon(Icons.leaderboard_rounded, size: 14, color: Colors.white),
                                    label: Text(state.t('Board', 'بورڈ'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primaryDeep.withValues(alpha: 0.1)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    onPressed: () async {
                                      final shared = state.sharedStreak!;
                                       final appUrl = 'https://play.google.com/store/apps/details?id=com.sajda.dataplus';
                                      if (shared.inviteCode.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(state.t('No invite code available', 'انوائٹ کوڈ دستیاب نہیں'))),
                                        );
                                        return;
                                      }
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
                                    },
                                    icon: Icon(Icons.share_rounded, size: 18, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SharedMembersList(sharedStreak: state.sharedStreak!, members: state.sharedMembers),
                          const SizedBox(height: 24),
                        ],
                        _SectionHeader(icon: Icons.history_rounded, title: state.t('Streak History', 'سٹریک کی تاریخ')),
                        const SizedBox(height: 12),
                        const _StreakHistoryList(),
                        const SizedBox(height: 24),
                        if (streak.status == 'active')
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final error = await context.read<AppState>().pauseStreak();
                                    if (error != null && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                                    }
                                  },
                                  icon: Icon(Icons.pause_rounded, color: AppColors.primary),
                                  label: Text(state.t('Pause', 'روکیں'), style: TextStyle(color: AppColors.primary)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const JoinStreakScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.group_add_rounded),
                                  label: Text(state.t('Start Together', 'اکٹھے شروع کریں')),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primaryDeep.withValues(alpha: 0.08)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? AppColors.darkSurface : AppColors.lightCard,
            isDark ? AppColors.darkSurfaceAlt : AppColors.lightBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primaryDeep.withValues(alpha: 0.1)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDark ? AppColors.darkMuted : AppColors.lightMutedText, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TodayPrayerList extends StatelessWidget {
  const _TodayPrayerList();

  Future<void> _confirmPrayer(BuildContext context, Map<String, String> prayer, bool isDone, AppState state) async {
    final label = state.language == 'ur' ? prayer['ur']! : prayer['name']!;
    final action = isDone
        ? state.t('Unmark', 'واپس کریں')
        : state.t('Mark as Prayed', 'نماز پڑھ لی');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDone
                        ? [AppColors.danger, AppColors.danger.withValues(alpha: 0.8)]
                        : [AppColors.primary, AppColors.primaryDeep],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDone ? AppColors.danger : AppColors.primary).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  isDone ? Icons.undo_rounded : Icons.mosque_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isDone
                    ? state.t('Unmark $label?', '$label واپس کریں؟')
                    : state.t('Did you pray $label?', 'کیا آپ نے $label پڑھ لی؟'),
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isDone
                    ? state.t('This prayer will be unmarked.', 'یہ نماز نشان حذف ہو جائے گی۔')
                    : state.t('Your streak will be updated.', 'آپ کی سٹریک اپ ڈیٹ ہو جائے گی۔'),
                style: Theme.of(ctx).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(state.t('Cancel', 'منسوخ'), style: TextStyle(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: isDone ? AppColors.danger : AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(action),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      final error = await state.updatePrayerCompletion(prayer['key']!, !isDone);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = state.todayProgress;
    final prayers = [
      {'name': 'Fajr', 'ur': 'فجر', 'key': 'fajr', 'time': '4:30 AM'},
      {'name': 'Dhuhr', 'ur': 'ظہر', 'key': 'dhuhr', 'time': '12:15 PM'},
      {'name': 'Asr', 'ur': 'عصر', 'key': 'asr', 'time': '3:45 PM'},
      {'name': 'Maghrib', 'ur': 'مغرب', 'key': 'maghrib', 'time': '6:30 PM'},
      {'name': 'Isha', 'ur': 'عشاء', 'key': 'isha', 'time': '8:00 PM'},
    ];
    final completedCount = prayers.where((p) => today[p['key']] == true).length;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.t('Prayers Completed', 'نمازیں مکمل'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: completedCount == 5
                            ? LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDeep],
                              )
                            : null,
                        color: completedCount == 5 ? null : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: completedCount == 5
                            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Text(
                        '$completedCount / 5',
                        style: TextStyle(
                          color: completedCount == 5 ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: completedCount / 5,
                    minHeight: 8,
                    backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.lightDivider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...prayers.map((p) {
          final done = today[p['key']] == true;
          return GestureDetector(
            onTap: () => _confirmPrayer(context, p, done, state),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: done
                    ? LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.12),
                          AppColors.primaryDeep.withValues(alpha: 0.06),
                        ],
                      )
                    : null,
                color: done ? null : (isDark ? AppColors.darkSurface : AppColors.lightCard),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: done
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
                  width: done ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: done
                          ? LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDeep],
                            )
                          : null,
                      color: done ? null : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightDivider),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      done ? Icons.check_rounded : Icons.add_rounded,
                      color: done ? Colors.white : (isDark ? AppColors.darkMuted : AppColors.lightMutedText),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.language == 'ur' ? p['ur']! : p['name']!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: done ? FontWeight.w700 : FontWeight.w600,
                            color: done
                                ? AppColors.primary
                                : (isDark ? AppColors.darkText : AppColors.lightText),
                          ),
                        ),
                        if (!done)
                          Text(
                            state.t('Tap to confirm', 'ٹیپ کر کے تصدیق کریں'),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, color: AppColors.primary),
                          ),
                      ],
                    ),
                  ),
                  if (done)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            state.t('Prayed', 'پڑھ لی'),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? AppColors.darkMuted : AppColors.lightMutedText,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }).toList(), // ignore: unnecessary_to_list_in_spreads
        if (completedCount == 5)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDeep],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.celebration_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  state.t('All prayers completed! MashaAllah', '!سب نمازیں مکمل مashaاللہ'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WeekView extends StatelessWidget {
  const _WeekView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final history = state.streakHistory;
    final now = DateTime.now();
    final weekDays = <Widget>[];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final entry = history.where((e) => e.date == dateStr).toList().firstOrNull;
      final isToday = i == 0;
      final isComplete = entry?.isComplete ?? false;

      weekDays.add(
        Expanded(
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isComplete
                      ? LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDeep],
                        )
                      : null,
                  color: isComplete ? null : (isToday ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent),
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isComplete
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Icon(
                  isComplete ? Icons.check_rounded : Icons.circle_outlined,
                  color: isComplete ? Colors.white : (isToday ? AppColors.primary : (isDark ? AppColors.darkMuted : AppColors.lightMutedText)),
                  size: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('E').format(date).substring(0, 1),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isToday ? AppColors.primary : (isDark ? AppColors.darkMuted : AppColors.lightMutedText),
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(children: weekDays);
  }
}

class _StreakHistoryList extends StatelessWidget {
  const _StreakHistoryList();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final history = state.streakHistory;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            context.read<AppState>().t('No history yet', 'ابھی تک کوئی تاریخ نہیں'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDark ? AppColors.darkMuted : AppColors.lightMutedText),
          ),
        ),
      );
    }

    return Column(
      children: history.take(10).map((entry) {
        final date = DateTime.tryParse(entry.date);
        final dateStr = date != null ? DateFormat('MMM d, y').format(date) : entry.date;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark ? AppColors.darkSurface : AppColors.lightCard,
                isDark ? AppColors.darkSurfaceAlt : AppColors.lightBackground,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: entry.isComplete
                      ? LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDeep],
                        )
                      : null,
                  color: entry.isComplete ? null : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightDivider),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  entry.isComplete ? Icons.check_rounded : Icons.circle_outlined,
                  color: entry.isComplete ? Colors.white : (isDark ? AppColors.darkMuted : AppColors.lightMutedText),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(dateStr, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
              if (entry.isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${entry.prayerCounts}/5',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SharedMembersList extends StatelessWidget {
  final SharedStreakModel sharedStreak;
  final List<StreakMemberModel> members;

  const _SharedMembersList({required this.sharedStreak, required this.members});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = members.where((m) => m.isActive).toList()
      ..sort((a, b) => b.currentDay.compareTo(a.currentDay));
    final top3 = active.take(3).toList();

    final medalColors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SharedStreakBoardScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.primaryDeep.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDeep],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.leaderboard_rounded, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sharedStreak.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primaryDeep.withValues(alpha: 0.1)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${sharedStreak.currentDay}/${sharedStreak.goalDays}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 14),
              if (top3.isNotEmpty)
                ...top3.asMap().entries.map((entry) {
                  final i = entry.key;
                  final m = entry.value;
                  final rank = i + 1;
                  final medal = medalColors[rank] ?? AppColors.primary;
                  final isMe = m.userId == state.userId;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: medal.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: rank <= 3
                                ? Icon(
                                    rank == 1 ? Icons.emoji_events_rounded : (rank == 2 ? Icons.looks_two_rounded : Icons.looks_3_rounded),
                                    size: 14,
                                    color: medal,
                                  )
                                : Text('$rank', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: medal.withValues(alpha: 0.15),
                          child: Text(
                            m.displayName.isNotEmpty ? m.displayName[0].toUpperCase() : '?',
                            style: TextStyle(color: medal, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            m.displayName + (isMe ? ' (${state.t('You', 'آپ')})' : ''),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isMe ? AppColors.primary : (isDark ? AppColors.darkText : AppColors.lightText),
                            ),
                          ),
                        ),
                        Text(
                          '${m.currentDay} days',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: medal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              if (active.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '+${active.length - 3} ${state.t('more members', 'مزید ممبران')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  state.t('Tap to view full board', 'بورڈ دیکھنے کے لیے ٹیپ کریں'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





