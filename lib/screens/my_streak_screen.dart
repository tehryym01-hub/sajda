import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../services/date_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/streak_invite_text.dart';
import 'create_streak_screen.dart';
import 'invite_share_card.dart';
import 'join_streak_screen.dart';
import 'shared_streak_board_screen.dart';

/// Full Streak Detail screen: header stats, today's progress, members,
/// history, past streaks and role-aware actions (pause/resume, extend,
/// leave, end/cancel). History is never destroyed.
class MyStreakScreen extends StatefulWidget {
  const MyStreakScreen({super.key});

  @override
  State<MyStreakScreen> createState() => _MyStreakScreenState();
}

class _MyStreakScreenState extends State<MyStreakScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      state.loadStreakHistory();
      state.loadPastStreaks();
      if (state.streak == null) state.loadMyStreak();
    });
  }

  Future<void> _shareInvite(AppState state) async {
    final streak = state.streak;
    if (streak == null || !streak.isShared) return;
    final shared = state.sharedStreak;
    if (shared == null || shared.inviteCode.isEmpty) {
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
          appUrl: 'https://play.google.com/store/apps/details?id=com.sajda.dataplus',
          creatorName: state.displayName,
        ),
      ),
    );
  }

  Future<void> _shareProgress(AppState state, StreakModel streak) async {
    final data = await state.shareStreak(streak.id);
    if (!mounted) return;
    if (data == null) {
      // Solo streaks have no invite — share a progress message instead.
      final message = '${state.displayName ?? 'Someone'} is on a '
          '${streak.currentStreak}-day Salah streak (${streak.currentDay}/${streak.goalDays} days)! 🤲';
      await SharePlus.instance.share(ShareParams(text: message));
      return;
    }
    final message = buildStreakShareMessage(
      shareText: data['shareText']?.toString() ?? '',
      inviteCode: data['inviteCode']?.toString() ?? '',
      inviteUrl: data['inviteUrl']?.toString() ?? '',
    );
    if (message.isNotEmpty) {
      await SharePlus.instance.share(
        ShareParams(text: message, subject: state.t('Join my Salah Streak', 'میرے صلاح سٹریک میں شامل ہوں')),
      );
    }
  }

  Future<void> _confirmLeave(AppState state) async {
    final confirmed = await _confirmAction(
      state,
      title: state.t('Leave Streak?', 'سٹریک چھوڑیں؟'),
      body: state.t(
        'You will stop participating in this group streak. Your history is preserved.',
        'آپ اس گروپ سٹریک سے علیحدہ ہو جائیں گے۔ آپ کی تاریخ محفوظ رہے گی۔',
      ),
      confirmLabel: state.t('Leave', 'چھوڑیں'),
      danger: true,
    );
    if (confirmed != true || !mounted) return;
    final error = await state.leaveSharedStreak(state.streak!.sharedStreakId!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? state.t('You left the streak', 'آپ سٹریک چھوڑ گئے'))),
    );
    if (error == null) Navigator.of(context).pop();
  }

  Future<void> _confirmEnd(AppState state) async {
    final confirmed = await _confirmAction(
      state,
      title: state.t('End Streak for Everyone?', 'سب کے لیے سٹریک ختم کریں؟'),
      body: state.t(
        'As the creator you can end this streak for all members. All history is preserved.',
        'بنا کر کے آپ یہ سٹریک تمام ممبران کے لیے ختم کر سکتے ہیں۔ تمام تاریخ محفوظ رہے گی۔',
      ),
      confirmLabel: state.t('End Streak', 'ختم کریں'),
      danger: true,
    );
    if (confirmed != true || !mounted) return;
    final error = await state.endSharedStreak(state.streak!.sharedStreakId!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? state.t('Streak ended', 'سٹریک ختم ہو گئی'))),
    );
  }

  Future<void> _confirmCancel(AppState state) async {
    final confirmed = await _confirmAction(
      state,
      title: state.t('Cancel Streak?', 'سٹریک منسوخ کریں؟'),
      body: state.t(
        'Your streak will end now. Your full history is preserved in Past Streaks.',
        'آپ کی سٹریک اب ختم ہو جائے گی۔ آپ کی مکمل تاریخ محفوظ رہے گی۔',
      ),
      confirmLabel: state.t('Cancel Streak', 'منسوخ کریں'),
      danger: true,
    );
    if (confirmed != true || !mounted) return;
    final error = await state.cancelStreak();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? state.t('Streak cancelled', 'سٹریک منسوخ ہو گئی'))),
    );
    if (error == null) Navigator.of(context).pop();
  }

  Future<bool?> _confirmAction(
    AppState state, {
    required String title,
    required String body,
    required String confirmLabel,
    bool danger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        content: Text(body, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(state.t('Keep Streak', 'جاری رکھیں')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: danger ? AppColors.danger : AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

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
                    Container(
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
                    const SizedBox(height: 24),
                    Text(
                      state.t('No streak yet', 'ابھی تک کوئی سٹریک نہیں'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CreateStreakScreen()),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(state.t('Start a Streak', 'سٹریک شروع کریں')),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const JoinStreakScreen()),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          icon: Icon(Icons.group_add_rounded, color: AppColors.primary),
                          label: Text(state.t('Join', 'شامل ہوں')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 230,
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
                                style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                              ),
                              Text(
                                state.t('Current Streak', 'موجودہ سٹریک'),
                                style: const TextStyle(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
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
                    if (streak.isActive)
                      Container(
                        margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => _showExtendStreakDialog(context, state, streak),
                          icon: const Icon(Icons.flag_rounded, color: Colors.white),
                          tooltip: state.t('Increase Target', 'ہدف بڑھائیں'),
                        ),
                      ),
                    Container(
                      margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => _shareProgress(state, streak),
                        icon: const Icon(Icons.share_rounded, color: Colors.white),
                        tooltip: state.t('Share', 'شیئر کریں'),
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
                        // ── Meta info ──
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
                                icon: streak.isActive
                                    ? Icons.play_circle_rounded
                                    : (streak.isPaused ? Icons.pause_circle_rounded : Icons.stop_circle_rounded),
                                label: state.t('Status', 'حیثیت'),
                                value: _statusLabel(state, streak),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoTile(
                                icon: Icons.calendar_month_rounded,
                                label: state.t('Started', 'آغاز'),
                                value: DateFormat('MMM d, y').format(streak.startDate.toLocal()),
                              ),
                            ),
                            const SizedBox(width: 14),
                            if (streak.isShared)
                              Expanded(
                                child: _InfoTile(
                                  icon: Icons.person_rounded,
                                  label: state.t('Created by', 'بنایا'),
                                  value: state.amStreakCreator
                                      ? state.t('You', 'آپ')
                                      : (state.sharedStreak?.creatorName.isNotEmpty == true
                                          ? state.sharedStreak!.creatorName
                                          : '—'),
                                ),
                              )
                            else
                              Expanded(
                                child: _InfoTile(
                                  icon: Icons.person_outline_rounded,
                                  label: state.t('Type', 'قسم'),
                                  value: state.t('Personal', 'ذاتی'),
                                ),
                              ),
                          ],
                        ),

                        if (streak.hasEnded) ...[
                          const SizedBox(height: 20),
                          _EndedBanner(state: state, streak: streak),
                        ],

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

                        // ── Shared streak members ──
                        if (streak.isShared && state.sharedStreak != null) ...[
                          _SectionHeader(
                            icon: Icons.leaderboard_rounded,
                            title: state.sharedStreak!.title,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDeep]),
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                  ),
                                  child: TextButton.icon(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const SharedStreakBoardScreen()),
                                    ),
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
                                    onPressed: () => _shareInvite(state),
                                    icon: const Icon(Icons.group_add_rounded, size: 18, color: AppColors.primary),
                                    tooltip: state.t('Invite', 'انوائٹ'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SharedMembersList(sharedStreak: state.sharedStreak!, members: state.sharedMembers),
                          const SizedBox(height: 24),
                        ],

                        // ── Day-by-day history of this streak ──
                        _SectionHeader(icon: Icons.history_rounded, title: state.t('Streak History', 'سٹریک کی تاریخ')),
                        const SizedBox(height: 12),
                        const _StreakHistoryList(),

                        // ── Past (ended) streaks — never deleted ──
                        if (state.pastStreaks.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _SectionHeader(icon: Icons.inventory_2_rounded, title: state.t('Past Streaks', 'پچھلی سٹریک')),
                          const SizedBox(height: 12),
                          _PastStreaksList(pastStreaks: state.pastStreaks),
                        ],
                        const SizedBox(height: 24),

                        // ── Role-aware actions ──
                        _ActionsSection(
                          onLeave: streak.isShared && !state.amStreakCreator && streak.isActive
                              ? () => _confirmLeave(state)
                              : null,
                          onEnd: streak.isShared && state.amStreakCreator && streak.isActive
                              ? () => _confirmEnd(state)
                              : null,
                          onCancel: !streak.isShared && (streak.isActive || streak.isPaused)
                              ? () => _confirmCancel(state)
                              : null,
                        ),
                        if (streak.hasEnded)
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CreateStreakScreen()),
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(state.t('Create New Streak', 'نئی سٹریک بنائیں'), style: const TextStyle(fontWeight: FontWeight.w700)),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _statusLabel(AppState state, StreakModel streak) {
    switch (streak.status) {
      case 'active':
        return state.t('Active', 'فعال');
      case 'paused':
        return state.t('Paused', 'روک دیا');
      case 'completed':
        return state.t('Completed', 'مکمل');
      case 'cancelled':
        return state.t('Cancelled', 'منسوخ');
      default:
        return state.t('Ended', 'ختم');
    }
  }
}

class _EndedBanner extends StatelessWidget {
  final AppState state;
  final StreakModel streak;

  const _EndedBanner({required this.state, required this.streak});

  @override
  Widget build(BuildContext context) {
    final isGoalReached = streak.isCompleted;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isGoalReached ? AppColors.primary : AppColors.danger).withValues(alpha: 0.1),
            (isGoalReached ? AppColors.primaryDeep : AppColors.danger).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isGoalReached ? AppColors.primary : AppColors.danger).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isGoalReached ? Icons.emoji_events_rounded : Icons.local_fire_department_outlined,
            color: isGoalReached ? AppColors.primary : AppColors.danger,
            size: 26,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isGoalReached
                  ? state.t('Goal Reached — MashaAllah! History is preserved.', 'ہدف مکمل — ماشاءاللہ! تاریخ محفوظ ہے۔')
                  : state.t(
                      'This streak has ended. Your ${streak.currentDay}-day history is preserved below.',
                      'یہ سٹریک ختم ہو گئی۔ آپ کے ${streak.currentDay} دن کی تاریخ نیچے محفوظ ہے۔',
                    ),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  final VoidCallback? onLeave;
  final VoidCallback? onEnd;
  final VoidCallback? onCancel;

  const _ActionsSection({this.onLeave, this.onEnd, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final streak = state.streak;
    if (streak == null) return const SizedBox.shrink();

    final children = <Widget>[];

    if (streak.isPaused) {
      children.add(Expanded(
        child: FilledButton.icon(
          onPressed: () => state.resumeStreak(),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(state.t('Resume', 'دوبارہ شروع کریں')),
        ),
      ));
    }

    if (children.isNotEmpty && (onLeave != null || onEnd != null || onCancel != null)) {
      children.add(const SizedBox(width: 12));
    }

    if (onLeave != null) {
      children.add(Expanded(
        child: OutlinedButton.icon(
          onPressed: onLeave,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
          label: Text(state.t('Leave Streak', 'سٹریک چھوڑیں'), style: TextStyle(color: AppColors.danger)),
        ),
      ));
    } else if (onEnd != null) {
      children.add(Expanded(
        child: OutlinedButton.icon(
          onPressed: onEnd,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: Icon(Icons.stop_circle_outlined, color: AppColors.danger, size: 20),
          label: Text(state.t('End Streak', 'سٹریک ختم کریں'), style: TextStyle(color: AppColors.danger)),
        ),
      ));
    } else if (onCancel != null) {
      children.add(Expanded(
        child: OutlinedButton.icon(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
          label: Text(state.t('Cancel Streak', 'سٹریک منسوخ کریں'), style: TextStyle(color: AppColors.danger)),
        ),
      ));
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Row(children: children);
  }
}

class _PastStreaksList extends StatelessWidget {
  final List<StreakModel> pastStreaks;

  const _PastStreaksList({required this.pastStreaks});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: pastStreaks.map((s) {
        final label = s.status == 'completed'
            ? state.t('Completed', 'مکمل')
            : s.status == 'cancelled'
                ? state.t('Cancelled', 'منسوخ')
                : state.t('Ended', 'ختم');
        final range = '${DateFormat('MMM d, y').format(s.startDate.toLocal())}'
            ' – ${s.endDate != null ? DateFormat('MMM d, y').format(s.endDate!.toLocal()) : '…'}';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.25),
                    AppColors.primaryDeep.withValues(alpha: 0.1),
                  ]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  s.status == 'completed' ? Icons.emoji_events_rounded : Icons.local_fire_department_outlined,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(range, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      '$label · ${s.currentDay}/${s.goalDays} ${state.t('days', 'دن')} · ${state.t('Best', 'بہترین')}: ${s.longestStreak}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: isDark ? AppColors.darkMuted : AppColors.lightMutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Increase the streak TARGET without touching progress. Current days stay
/// exactly as they are — only goalDays/endDate change (backend enforces this
/// and syncs the whole group for shared streaks, creator only).
Future<void> _showExtendStreakDialog(BuildContext context, AppState state, StreakModel streak) async {
  final presets = [streak.goalDays + 7, streak.goalDays + 14, streak.goalDays + 30, streak.goalDays + 90]
      .where((d) => d <= 365)
      .toList();
  final controller = TextEditingController();
  var selected = presets.isNotEmpty ? presets.last : 365;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(state.t('Increase Target', 'ہدف بڑھائیں'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.t(
                'Your current ${streak.currentDay} days are safe — only the goal changes.',
                'آپ کے موجودہ ${streak.currentDay} دن محفوظ رہیں گے — صرف ہدف تبدیل ہوگا۔',
              ),
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final d in presets)
                  GestureDetector(
                    onTap: () => setDialogState(() => selected = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: selected == d
                            ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDeep])
                            : null,
                        color: selected == d ? null : AppColors.primaryPill(Theme.of(ctx).brightness == Brightness.dark),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected == d ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '$d ${state.t('days', 'دن')}',
                        style: TextStyle(
                          color: selected == d ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: state.t('Custom target (3-365)', 'اپنی مرضی (3-365)'),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) {
                final parsed = int.tryParse(v.trim());
                if (parsed != null) setDialogState(() => selected = parsed);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(state.t('Cancel', 'منسوخ'))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(state.t('Update Goal', 'ہدف اپ ڈیٹ کریں')),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true || selected <= streak.goalDays || !context.mounted) return;
  final error = await state.extendStreakGoal(selected);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        error ?? state.t('Target updated to $selected days — keep going!', 'ہدف $selected دن ہو گیا — جاری رکھیں!'),
      ),
    ),
  );
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
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 16), overflow: TextOverflow.ellipsis),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
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
          Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
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
      {'name': 'Fajr', 'ur': 'فجر', 'key': 'fajr'},
      {'name': 'Dhuhr', 'ur': 'ظہر', 'key': 'dhuhr'},
      {'name': 'Asr', 'ur': 'عصر', 'key': 'asr'},
      {'name': 'Maghrib', 'ur': 'مغرب', 'key': 'maghrib'},
      {'name': 'Isha', 'ur': 'عشاء', 'key': 'isha'},
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
                            ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDeep])
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
                          ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDeep])
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
                    child: Text(
                      state.language == 'ur' ? p['ur']! : p['name']!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: done ? FontWeight.w700 : FontWeight.w600,
                        color: done
                            ? AppColors.primary
                            : (isDark ? AppColors.darkText : AppColors.lightText),
                      ),
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
                          const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
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
        }),
        if (completedCount == 5)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDeep]),
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
                Flexible(
                  child: Text(
                    state.t('All prayers completed! MashaAllah', 'ماشاءاللہ! تمام نمازیں مکمل'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Week strip keyed by LOCATION-timezone date keys so it always agrees with
/// the streak day keys stored on the backend.
class _WeekView extends StatelessWidget {
  const _WeekView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final history = state.streakHistory;
    final tz = state.locationTimezone;
    final now = DateTime.now();

    final weekDays = <Widget>[];
    for (int i = 6; i >= 0; i--) {
      final dayDate = DateTime(now.year, now.month, now.day - i);
      final dateStr = dateService.formatDateAsYYYYMMDD(date: dayDate, timezone: tz);
      final entry = history.where((e) => e.date == dateStr).firstOrNull;
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
                      ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDeep])
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
                DateFormat('E').format(dayDate).substring(0, 1),
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

    final sorted = history.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: sorted.take(14).map((entry) {
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
                      ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDeep])
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
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SharedStreakBoardScreen()),
      ),
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
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDeep]),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: const Icon(Icons.leaderboard_rounded, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${active.length} ${state.t('members', 'ممبران')}',
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
                  const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 14),
              if (top3.isNotEmpty)
                ...top3.asMap().entries.map((entry) {
                  final i = entry.key;
                  final m = entry.value;
                  final rank = i + 1;
                  final medal = medalColors[rank] ?? AppColors.primary;
                  final isMe = m.userId == state.userId || m.isCurrentUser;
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
