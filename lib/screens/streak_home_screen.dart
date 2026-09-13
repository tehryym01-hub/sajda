import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firebase_auth_service.dart';
import '../state/app_state.dart';
import '../state/streak_state.dart';
import '../theme/app_theme.dart';
import '../widgets/streak/streak_components.dart';
import 'create_group_screen.dart';
import 'discover_groups_screen.dart';
import 'group_dashboard_screen.dart';
import 'join_with_code_screen.dart';
import 'my_groups_screen.dart';
import 'solo_dashboard_screen.dart';

/// The Streak tab: auth gate → Solo card + Friends & Family card.
class StreakHomeScreen extends StatefulWidget {
  const StreakHomeScreen({super.key});

  @override
  State<StreakHomeScreen> createState() => _StreakHomeScreenState();
}

class _StreakHomeScreenState extends State<StreakHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppState>();
      if (app.isAuthenticated) {
        context.read<StreakState>().initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: app.isAuthenticated ? const _StreakHome() : const _EmailAuthGate(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Auth gate — passwordless email magic link. Streak data lives on the
// server bound to a verified email, so sign-in is required. After the
// user taps the link, main.dart completes sign-in; this gate disappears
// automatically once AppState.isAuthenticated flips true.
// ─────────────────────────────────────────────────────────────────────

class _EmailAuthGate extends StatefulWidget {
  const _EmailAuthGate();

  @override
  State<_EmailAuthGate> createState() => _EmailAuthGateState();
}

class _EmailAuthGateState extends State<_EmailAuthGate> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String _sentTo = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _friendlyError(String error) {
    final state = context.read<AppState>();
    if (error == 'network') {
      return state.t('No connection. Try again.', 'انٹرنیٹ نہیں۔ دوبارہ کوشش کریں۔');
    }
    if (error == 'invalid_email') {
      return state.t('Please enter a valid email', 'براہ کرم درست ای میل درج کریں');
    }
    if (error.startsWith('[') || error.contains('channel-error') || error.contains('firebase_init')) {
      return state.t('Service unavailable. Try again later.', 'سروس دستیاب نہیں۔ بعد میں کوشش کریں۔');
    }
    if (error.contains('too-many-requests')) {
      return state.t('Too many attempts. Try again later.', 'بہت زیادہ کوششیں۔ بعد میں کوشش کریں۔');
    }
    return state.t('Could not send link: $error', 'لنک نہیں بھیج سکے: $error');
  }

  Future<void> _send() async {
    final state = context.read<AppState>();
    final email = _emailController.text.trim();
    if (!email.contains('@') || email.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.t('Please enter a valid email', 'براہ کرم درست ای میل درج کریں'))),
      );
      return;
    }
    setState(() => _loading = true);
    final error = await FirebaseAuthService.instance.sendMagicLink(
      email,
      displayName: _nameController.text.trim(),
    );
    setState(() {
      _loading = false;
      if (error == null) {
        _sent = true;
        _sentTo = email;
      }
    });
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_sent) {
      return _CheckInboxView(
        email: _sentTo,
        isDark: isDark,
        onResend: _send,
        onChangeEmail: () => setState(() => _sent = false),
        loading: _loading,
      );
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.gradientTeal),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 10))],
              ),
              child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 28),
            Text(
              state.t('Welcome to Sajda Streaks', 'سجدہ اسٹریک میں خوش آمدید'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              state.t(
                'Sign in with your email — no password. Your streak is saved to your account and survives reinstalls.',
                'ای میل سے داخل ہوں — پاس ورڈ کی ضرورت نہیں۔ آپ کا سٹریک اکاؤنٹ سے محفوظ رہے گا۔',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? AppColors.darkMuted : AppColors.lightSecondaryText,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: isDark ? AppColors.darkText : AppColors.lightText),
              decoration: InputDecoration(
                hintText: state.t('Your name (optional)', 'آپ کا نام (اختیاری)'),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.lightCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: isDark ? AppColors.darkText : AppColors.lightText),
              decoration: InputDecoration(
                hintText: state.t('Email address', 'ای میل ایڈریس'),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.lightCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onSubmitted: (_) => _send(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(
                        state.t('Send sign-in link', 'داخلے کا لنک بھیجیں'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckInboxView extends StatelessWidget {
  final String email;
  final bool isDark;
  final bool loading;
  final VoidCallback onResend;
  final VoidCallback onChangeEmail;

  const _CheckInboxView({
    required this.email,
    required this.isDark,
    required this.loading,
    required this.onResend,
    required this.onChangeEmail,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightCard,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mark_email_read_outlined,
                  color: AppColors.primary, size: 44),
            ),
            const SizedBox(height: 26),
            Text(
              state.t('Check your email', 'اپنی ای میل چیک کریں'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              state.t(
                'We sent a sign-in link to $email. Tap it to open the app — your streak is waiting.',
                'ہم نے $email پر داخلے کا لنک بھیجا ہے۔ ایپ کھولنے کے لیے اس پر ٹیپ کریں۔',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? AppColors.darkMuted : AppColors.lightSecondaryText,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : onResend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(
                        state.t('Resend link', 'لنک دوبارہ بھیجیں'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onChangeEmail,
              child: Text(state.t('Use a different email', 'دوسرا ای میل استعمال کریں')),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Main content
// ─────────────────────────────────────────────────────────────────────

class _StreakHome extends StatelessWidget {
  const _StreakHome();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final streak = context.watch<StreakState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final refreshLabel = app.t('Refresh', 'ریفریش');

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.wait([
          streak.refreshSolo(),
          streak.refreshGroups(),
          streak.refreshNotifications(),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  app.t('Streaks', 'اسٹریک'),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ),
              _BellButton(unread: streak.unreadCount),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () {
                  streak.refreshSolo();
                  streak.refreshGroups();
                },
                icon: Icon(Icons.refresh_rounded, color: isDark ? AppColors.darkMuted : AppColors.lightSecondaryText),
                tooltip: refreshLabel,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── SOLO ──
          _SoloCard(dark: isDark),
          const SizedBox(height: 24),

          // ── FRIENDS & FAMILY ──
          StreakSectionHeader(
            title: app.t('Friends & Family', 'دوست اور گھر والے'),
            action: TextButton(
              onPressed: () => _push(context, const MyGroupsScreen()),
              child: Text(app.t('See all', 'سب دیکھیں')),
            ),
          ),
          _GroupsPreview(dark: isDark),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.group_add_rounded,
                  label: app.t('New group', 'نیا گروپ'),
                  onTap: () => _push(context, const CreateGroupScreen()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  icon: Icons.vpn_key_rounded,
                  label: app.t('Join with code', 'کوڈ سے شامل'),
                  onTap: () => _push(context, const JoinWithCodeScreen()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  icon: Icons.search_rounded,
                  label: app.t('Discover', 'تلاش'),
                  onTap: () => _push(context, const DiscoverGroupsScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  final int unread;
  const _BellButton({required this.unread});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => showNotificationsSheet(context),
          icon: Icon(
            Icons.notifications_none_rounded,
            size: 26,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _SoloCard extends StatelessWidget {
  final bool dark;
  const _SoloCard({required this.dark});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final streak = context.watch<StreakState>();
    final solo = streak.solo;
    final title = app.t('SOLO', 'اکیلے');

    final header = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: dark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const Spacer(),
          if (solo != null && solo.started)
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SoloDashboardScreen()),
              ),
              child: Row(
                children: [
                  Text(
                    app.t('Details', 'تفصیل'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
                ],
              ),
            ),
        ],
      ),
    );

    // Loading
    if (streak.soloPhase == StreakLoadPhase.loading && solo == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [header, const LoadingList()]);
    }

    // Error
    if (streak.soloPhase == StreakLoadPhase.error && solo == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          ErrorCard(
            message: streak.soloError == 'network'
                ? app.t('No connection. Check your internet.', 'انٹرنیٹ نہیں چل رہا۔')
                : (streak.soloError ?? ''),
            onRetry: () => streak.refreshSolo(),
          ),
        ],
      );
    }

    // Not started yet
    if (solo == null || !solo.started) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          EmptyStateCard(
            icon: Icons.local_fire_department_outlined,
            title: app.t('Start your solo streak', 'اپنا اکیلے کا سلسلہ شروع کریں'),
            subtitle: app.t(
              'Tick five prayers a day. Your streak grows with every complete day.',
              'روزانہ پانچ نمازیں ٹیک کریں۔ ہر مکمل دن کے ساتھ آپ کا سلسلہ بڑھے گا۔',
            ),
            action: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final err = await context.read<StreakState>().startSolo();
                  if (err != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(app.t('Start streak', 'سلسلہ شروع کریں')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Active solo — hero + ticks
    final today = solo.today;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SoloDashboardScreen()),
          ),
          child: StreakHero(
            count: solo.currentStreak,
            best: solo.bestStreak,
            compact: true,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dark ? AppColors.darkSurface : AppColors.lightCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: dark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TodayProgressHeader(
                completed: today.completedCount,
                needed: 5,
                dayComplete: today.isDayComplete,
              ),
              const SizedBox(height: 12),
              ...['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'].map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PrayerTickTile(
                    prayer: p,
                    done: today.of(p),
                    inFlight: streak.isPrayerInFlight(p),
                    onToggle: (done) async {
                      final err = await context.read<StreakState>().togglePrayer(p, done);
                      if (err != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_friendly(app, err))),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _friendly(AppState app, String err) {
    if (err == 'network') {
      return app.t('No connection. Check your internet.', 'انٹرنیٹ نہیں چل رہا۔');
    }
    return err;
  }
}

class _GroupsPreview extends StatelessWidget {
  final bool dark;
  const _GroupsPreview({required this.dark});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final streak = context.watch<StreakState>();
    final groups = streak.activeGroups.take(3).toList();

    if (streak.groupsPhase == StreakLoadPhase.loading && streak.groups.isEmpty) {
      return const LoadingList();
    }
    if (streak.groupsPhase == StreakLoadPhase.error && streak.groups.isEmpty) {
      return ErrorCard(
        message: streak.groupsError == 'network'
            ? app.t('No connection. Check your internet.', 'انٹرنیٹ نہیں چل رہا۔')
            : (streak.groupsError ?? ''),
        onRetry: () => streak.refreshGroups(),
      );
    }
    if (groups.isEmpty) {
      return EmptyStateCard(
        icon: Icons.family_restroom_rounded,
        title: app.t('No groups yet', 'ابھی کوئی گروپ نہیں'),
        subtitle: app.t(
          'Create a group with family, or join friends with an invite code.',
          'گھر والوں کے ساتھ گروپ بنائیں، یا انوائٹ کوڈ سے دوستوں میں شامل ہوں۔',
        ),
      );
    }
    return Column(
      children: [
        for (final g in groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GroupCard(
              group: g,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => GroupDashboardScreen(groupId: g.groupId)),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Notifications sheet (in-app feed; own actions excluded server-side)
// ─────────────────────────────────────────────────────────────────────

void showNotificationsSheet(BuildContext context) {
  final streak = context.read<StreakState>();
  final app = context.read<AppState>();
  streak.markNotificationsSeen();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkMuted : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                app.t('Notifications', 'اطلاعات'),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
            Flexible(
              child: Consumer<StreakState>(
                builder: (_, st, _) {
                  final items = st.notifications;
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: EmptyStateCard(
                        icon: Icons.notifications_none_rounded,
                        title: app.t('Nothing yet', 'ابھی کچھ نہیں'),
                        subtitle: app.t(
                          'Group activity will appear here.',
                          'گروپ کی سرگرمی یہاں نظر آئے گی۔',
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightDivider,
                    ),
                    itemBuilder: (_, i) {
                      final n = items[i];
                      return InkWell(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          if (n.groupId.isNotEmpty) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GroupDashboardScreen(groupId: n.groupId),
                              ),
                            );
                          }
                        },
                        child: ActivityRow(item: n, groupName: ' · ${n.notifGroupName}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  ).then((_) => streak.refreshNotifications());
}
