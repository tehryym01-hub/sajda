import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'create_streak_screen.dart';
import 'shared_streak_board_screen.dart';
import 'join_streak_screen.dart';
import 'invite_share_card.dart';
import 'streak_share_card.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.isAuthenticated && state.streak == null) {
        state.ensureAuthenticated().then((_) {
          if (mounted) state.loadMyStreak();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: state.isAuthenticated
            ? const _StreakHome()
            : const _NameSetupScreen(),
      ),
    );
  }
}

class _NameSetupScreen extends StatefulWidget {
  const _NameSetupScreen();

  @override
  State<_NameSetupScreen> createState() => _NameSetupScreenState();
}

class _NameSetupScreenState extends State<_NameSetupScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<AppState>().t('Please enter your name', 'براہ کرم اپنا نام درج کریں'))),
      );
      return;
    }
    setState(() => _loading = true);
    final error = await context.read<AppState>().register(name);
    if (error == null && mounted) {
      await context.read<AppState>().loadMyStreak();
    }
    setState(() => _loading = false);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
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
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(Icons.local_fire_department_rounded, size: 64, color: Colors.white),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              state.t('Salah Streak', 'صلاح سٹریک'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              state.t('Pray together. Stay consistent.', 'اکٹھے پڑھیں۔ مستقل رہیں۔'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.lightMutedText,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _continue(),
                decoration: InputDecoration(
                  hintText: state.t('Your Name', 'آپ کا نام'),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _loading ? null : _continue,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _loading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text(state.t('Continue', 'جاری رکھیں'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakHome extends StatefulWidget {
  const _StreakHome();

  @override
  State<_StreakHome> createState() => _StreakHomeState();
}

class _StreakHomeState extends State<_StreakHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initStreak();
    });
  }

  Future<void> _initStreak() async {
    final state = context.read<AppState>();
    if (state.isAuthenticated) {
      if (state.streak == null) {
        await state.ensureAuthenticated();
        await state.loadMyStreak();
      }
    }
  }

  void _showInviteInfoDialog(BuildContext context, AppState state, String appUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDeep]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                state.t('Invite Friends', 'دوستوں کو بلائیں'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                state.t(
                  'Share the app link with your friends so they can join your streak.',
                  'اپنے دوستوں کو ایپ لنک شیئر کریں تاکہ وہ آپ کی سٹریک میں شامل ہو سکیں۔',
                ),
                style: TextStyle(fontSize: 14, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      state.t('App Link', 'ایپ لنک'),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      appUrl,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(state.t('OK', 'ٹھیک ہے'), style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = state.streak;
    final today = state.todayProgress;
    final completedCount = [today['fajr'], today['dhuhr'], today['asr'], today['maghrib'], today['isha']].where((p) => p == true).length;

    return RefreshIndicator(
      onRefresh: () async {
        if (state.isAuthenticated) {
          final appState = context.read<AppState>();
          await appState.ensureAuthenticated();
          await appState.loadMyStreak();
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.streakError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.streakError!,
                        style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.t('Salah Streak', 'صلاح سٹریک'),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 26),
                      ),
                      if (state.displayName != null && state.displayName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${state.t('Welcome', 'خوش آمدید')}, ${state.displayName!}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkMuted : AppColors.lightMutedText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (streak != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Invite Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDeep],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            final appUrl = 'https://play.google.com/store/apps/details?id=com.sajda.dataplus';
                            if (state.sharedStreak != null && state.sharedStreak!.inviteCode.isNotEmpty) {
                              showDialog(
                                context: context,
                                builder: (ctx) {
                                  final bottomPadding = MediaQuery.of(ctx).viewPadding.bottom;
                                  return Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                                      ),
                                      child: SingleChildScrollView(
                                        padding: EdgeInsets.only(bottom: bottomPadding),
                                        child: InviteShareCard(
                                          streakTitle: state.sharedStreak!.title,
                                          inviteCode: state.sharedStreak!.inviteCode,
                                          appUrl: appUrl,
                                          creatorName: state.displayName,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else {
                              _showInviteInfoDialog(context, state, appUrl);
                            }
                          },
                          icon: const Icon(Icons.group_add_rounded, color: Colors.white, size: 20),
                          tooltip: state.t('Invite', 'انوائٹ'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Share Card Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDeep],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) {
                                final bottomPadding = MediaQuery.of(ctx).viewPadding.bottom;
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                                    ),
                                    child: SingleChildScrollView(
                                      padding: EdgeInsets.only(bottom: bottomPadding),
                                      child: StreakShareCard(
                                        displayName: state.displayName,
                                        streak: streak,
                                        sharedStreak: state.sharedStreak,
                                        sharedMembers: state.sharedMembers,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                          tooltip: state.t('Share', 'شیئر'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 28),

            if (streak != null && streak.isActive) ...[
              _StreakCard(streak: streak, todayProgress: state.todayProgress),
              const SizedBox(height: 20),
              _TodayPrayerCard(todayProgress: state.todayProgress, completedCount: completedCount),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department_rounded,
                      label: state.t('Current Streak', 'موجودہ سٹریک'),
                      value: '${streak.currentStreak}',
                      sub: state.t('days', 'دن'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.emoji_events_rounded,
                      label: state.t('Best Streak', 'بہترین سٹریک'),
                      value: '${streak.longestStreak}',
                      sub: state.t('days', 'دن'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (streak.isShared && state.sharedStreak != null)
                _SharedStreakPreview(
                  sharedStreak: state.sharedStreak!,
                  members: state.sharedMembers,
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JoinStreakScreen()),
                    );
                  },
                  icon: Icon(Icons.group_add_rounded, color: AppColors.primary),
                  label: Text(
                    state.t('Join a Streak', 'سٹریک میں شامل ہوں'),
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ] else if (streak != null && !streak.isActive && !streak.isCompleted) ...[
              _StreakCard(streak: streak, todayProgress: state.todayProgress),
              const SizedBox(height: 20),
              _TodayPrayerCard(todayProgress: state.todayProgress, completedCount: completedCount),
              const SizedBox(height: 20),
              Center(
                child: Container(
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
                      context.read<AppState>().resumeStreak();
                    },
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                    label: Text(state.t('Resume Streak', 'سٹریک دوبارہ شروع کریں'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JoinStreakScreen()),
                    );
                  },
                  icon: Icon(Icons.group_add_rounded, color: AppColors.primary),
                  label: Text(
                    state.t('Join a Streak', 'سٹریک میں شامل ہوں'),
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? AppColors.darkSurface : AppColors.lightCard,
                      isDark ? AppColors.darkSurfaceAlt : AppColors.lightBackground,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 1000),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primaryDeep.withValues(alpha: 0.1)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(Icons.local_fire_department_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.8)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      state.t('Start your Salah Streak', 'اپنی صلاح سٹریک شروع کریں'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.t('Build consistency one day at a time.', 'ایک دن میں ایک مستقل بنائیں۔'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkMuted : AppColors.lightMutedText,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CreateStreakScreen()),
                              );
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: Text(state.t('Start a Streak', 'سٹریک شروع کریں')),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const JoinStreakScreen()),
                              );
                            },
                            icon: Icon(Icons.group_add_rounded, color: AppColors.primary),
                            label: Text(state.t('Join a Streak', 'سٹریک میں شامل ہوں'), style: TextStyle(color: AppColors.primary)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final StreakModel streak;
  final Map<String, bool> todayProgress;

  const _StreakCard({required this.streak, required this.todayProgress});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final progress = streak.goalDays > 0 ? streak.currentDay / streak.goalDays : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${streak.currentStreak}',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            fontSize: 48,
                          ),
                        ),
                        Text(
                          state.t('Current Streak', 'موجودہ سٹریک'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${streak.longestStreak}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 32,
                          ),
                        ),
                        Text(
                          state.t('Best Streak', 'بہترین سٹریک'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${streak.currentDay} / ${streak.goalDays} ${state.t('days', 'دن')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayPrayerCard extends StatelessWidget {
  final Map<String, bool> todayProgress;
  final int completedCount;

  const _TodayPrayerCard({required this.todayProgress, required this.completedCount});

  Future<void> _confirmPrayer(BuildContext context, Map<String, String> prayer, bool isDone, AppState state) async {
    final label = state.language == 'ur' ? prayer['ur']! : prayer['name']!;

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
                    colors: [AppColors.primary, AppColors.primaryDeep],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Icon(Icons.mosque_rounded, size: 36, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                state.t('Did you pray $label?', 'کیا آپ نے $label پڑھ لی؟'),
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                state.t('Your streak will be updated.', 'آپ کی سٹریک اپ ڈیٹ ہو جائے گی۔'),
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
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(state.t('Yes, Prayed', 'ہاں، پڑھ لی')),
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
    final state = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prayers = [
      {'name': 'Fajr', 'ur': 'فجر', 'key': 'fajr'},
      {'name': 'Dhuhr', 'ur': 'ظہر', 'key': 'dhuhr'},
      {'name': 'Asr', 'ur': 'عصر', 'key': 'asr'},
      {'name': 'Maghrib', 'ur': 'مغرب', 'key': 'maghrib'},
      {'name': 'Isha', 'ur': 'عشاء', 'key': 'isha'},
    ];

    return Container(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.t('Today\'s Salah', 'آج کی نماز'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: completedCount == 5
                        ? LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDeep],
                          )
                        : null,
                    color: completedCount == 5 ? null : AppColors.primaryPill(isDark),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: completedCount == 5
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Text(
                    '$completedCount / 5',
                    style: TextStyle(
                      color: completedCount == 5 ? Colors.white : AppColors.primaryDeep,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...prayers.map((p) {
              final done = todayProgress[p['key']] == true;
              return GestureDetector(
                onTap: () => _confirmPrayer(context, p, done, state),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: done
                        ? LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.12),
                              AppColors.primaryDeep.withValues(alpha: 0.06),
                            ],
                          )
                        : null,
                    color: done ? null : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightBackground),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: done
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
                      width: done ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: done
                              ? LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryDeep],
                                )
                              : null,
                          color: done ? null : (isDark ? AppColors.darkSurface : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          done ? Icons.check_rounded : Icons.add_rounded,
                          color: done ? Colors.white : (isDark ? AppColors.darkMuted : AppColors.lightMutedText),
                          size: 18,
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
                        Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? AppColors.darkMuted : AppColors.lightMutedText),
                    ],
                  ),
                ),
              );
            }).toList(), // ignore: unnecessary_to_list_in_spreads
          ],
        ),
      ),
    );
  }
}

class _SharedStreakPreview extends StatelessWidget {
  final SharedStreakModel sharedStreak;
  final List<StreakMemberModel> members;

  const _SharedStreakPreview({required this.sharedStreak, required this.members});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final activeMembers = members.where((m) => m.isActive).toList()
      ..sort((a, b) => b.currentDay.compareTo(a.currentDay));

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
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.primaryDeep.withValues(alpha: 0.05),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDeep],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.leaderboard_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sharedStreak.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
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
              ...activeMembers.take(4).map((m) {
                final rank = activeMembers.indexOf(m) + 1;
                final medalColors = {
                  1: const Color(0xFFFFD700),
                  2: const Color(0xFFC0C0C0),
                  3: const Color(0xFFCD7F32),
                };
                final medal = medalColors[rank] ?? AppColors.primary;
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
                      Expanded(child: Text(m.displayName, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
                      Text(
                        '${m.currentDay} days',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: medal),
                      ),
                    ],
                  ),
                );
              }),
              if (activeMembers.length > 4)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${activeMembers.length - 4} ${state.t('more', 'مزید')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;

  const _StatCard({required this.icon, required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? AppColors.darkSurface : AppColors.lightCard,
            isDark ? AppColors.darkSurfaceAlt : AppColors.lightBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primaryDeep.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, fontSize: 28),
            ),
            Text(
              '$sub · $label',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.lightMutedText,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}





