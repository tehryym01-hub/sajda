import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'create_streak_screen.dart';
import 'my_streak_screen.dart';

/// Join-by-invite-code flow with a full state machine (never a dead end):
///  - joinable            → Join Streak
///  - already a member    → "You're already a member" + Open Streak
///  - left previously     → Rejoin
///  - streak ended        → ended info + Create New Streak
///  - streak full         → full message
///  - invalid / network   → distinct error states
class JoinStreakScreen extends StatefulWidget {
  const JoinStreakScreen({super.key});

  @override
  State<JoinStreakScreen> createState() => _JoinStreakScreenState();
}

class _JoinStreakScreenState extends State<JoinStreakScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  bool _joining = false;
  Map<String, dynamic>? _inviteData;
  String? _errorCode;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _errorCode = null;
      _errorMessage = null;
      _inviteData = null;
    });
    final result = await context.read<AppState>().getSharedStreakInvite(code);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _inviteData = result.data;
      _errorCode = result.code;
      _errorMessage = result.error;
    });
  }

  Future<void> _join() async {
    if (_joining) return;
    final code = _controller.text.trim().toUpperCase();
    setState(() => _joining = true);
    final result = await context.read<AppState>().joinSharedStreak(code);
    if (!mounted) return;
    setState(() => _joining = false);
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    if (result.alreadyMember) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AppState>().t(
              'You are already a member — opening your streak',
              'آپ پہلے ہی رکن ہیں — آپ کی سٹریک کھول رہے ہیں',
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    _openStreakDetail();
  }

  void _openStreakDetail() {
    Navigator.of(context).popUntil((r) => r.isFirst);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyStreakScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(state.t('Join a Streak', 'سٹریک میں شامل ہوں'), style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDeep]),
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        state.t('Enter invite code', 'انوائٹ کوڈ درج کریں'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 17),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                  onSubmitted: (_) => _lookup(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: state.t('Enter invite code', 'انوائٹ کوڈ درج کریں'),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primaryDeep.withValues(alpha: 0.08)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.tag_outlined, color: AppColors.primary, size: 20),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _loading || _joining ? null : _lookup,
                  icon: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search_rounded, color: Colors.white),
                  label: Text(state.t('Lookup', 'تلاش کریں')),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              if (_errorMessage != null && _errorCode != null) ...[
                const SizedBox(height: 20),
                _ErrorCard(code: _errorCode!, message: _errorMessage!, onRetry: _lookup),
              ] else if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                _ErrorCard(code: 'UNKNOWN', message: _errorMessage!, onRetry: _lookup),
              ],
              if (_inviteData != null) ...[
                const SizedBox(height: 24),
                _InviteResultCard(
                  data: _inviteData!,
                  joining: _joining,
                  onJoin: _join,
                  onOpenStreak: _openStreakDetail,
                  onCreateNew: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateStreakScreen()));
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String code;
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.code, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final isNetwork = code == 'NETWORK';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isNetwork ? AppColors.primary : AppColors.danger).withValues(alpha: 0.1),
            (isNetwork ? AppColors.primaryDeep : AppColors.danger).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isNetwork ? AppColors.primary : AppColors.danger).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            color: isNetwork ? AppColors.primary : AppColors.danger,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isNetwork
                  ? state.t('Could not reach the server. Check your connection and try again.', 'سرور سے رابطہ نہیں ہو سکا۔ کنکشن چیک کریں اور دوبارہ کوشش کریں۔')
                  : message,
              style: TextStyle(color: isNetwork ? AppColors.primary : AppColors.danger, fontWeight: FontWeight.w600),
            ),
          ),
          if (isNetwork)
            TextButton(onPressed: onRetry, child: Text(state.t('Retry', 'دوبارہ'))),
        ],
      ),
    );
  }
}

class _InviteResultCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool joining;
  final VoidCallback onJoin;
  final VoidCallback onOpenStreak;
  final VoidCallback onCreateNew;

  const _InviteResultCard({
    required this.data,
    required this.joining,
    required this.onJoin,
    required this.onOpenStreak,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shared = data['sharedStreak'] as Map<String, dynamic>? ?? {};
    final reason = data['reason']?.toString();
    final viewerMembership = data['viewerMembership']?.toString();
    final joinable = data['joinable'] == true;
    final alreadyMember = viewerMembership == 'active' || reason == 'ALREADY_MEMBER';
    final ended = reason == 'STREAK_NOT_ACTIVE';
    final full = reason == 'STREAK_FULL';

    final title = shared['title']?.toString() ?? state.t('Salah Streak', 'صلاح سٹریک');
    final rejoining = joinable && viewerMembership == 'left';

    return Container(
      decoration: BoxDecoration(
        gradient: ended
            ? LinearGradient(
                colors: [
                  AppColors.danger.withValues(alpha: 0.08),
                  AppColors.danger.withValues(alpha: 0.04),
                ],
              )
            : LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primaryDeep.withValues(alpha: 0.04),
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ended ? AppColors.danger.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: (ended ? AppColors.danger : AppColors.primary).withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: ended
                          ? [AppColors.danger, AppColors.danger.withValues(alpha: 0.8)]
                          : [AppColors.primary, AppColors.primaryDeep],
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                  ),
                  child: Icon(
                    ended ? Icons.local_fire_department_outlined : Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: state.t('Created by', 'بنایا'),
              value: shared['creatorName']?.toString() ?? 'Unknown',
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: state.t('Progress', 'پروگریس'),
              value: '${shared['currentDay'] ?? 0} / ${shared['goalDays'] ?? 0} ${state.t('days', 'دن')}',
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.people_outline_rounded,
              label: state.t('Members', 'ارکان'),
              value: '${shared['memberCount'] ?? 0} / ${shared['maxMembers'] ?? 10}',
            ),
            const SizedBox(height: 20),

            if (alreadyMember) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.t('You are already a member of this streak.', 'آپ پہلے ہی اس سٹریک کے رکن ہیں۔'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: joining ? null : onOpenStreak,
                  icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                  label: Text(state.t('Open My Streak', 'میری سٹریک کھولیں'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ] else if (ended) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.t(
                          'This streak has ended. Its history is preserved for its members.',
                          'یہ سٹریک ختم ہو چکی ہے۔ اس کی تاریخ ارکان کے لیے محفوظ ہے۔',
                        ),
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: isDark ? AppColors.darkText : AppColors.lightText),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: onCreateNew,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: Text(state.t('Create New Streak', 'نئی سٹریک بنائیں'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ] else if (full) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  state.t('This streak has reached its member limit.', 'اس سٹریک کے ممبران کی حد پوری ہو چکی ہے۔'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: joining ? null : onJoin,
                  icon: joining
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.group_add_rounded, color: Colors.white),
                  label: Text(
                    rejoining
                        ? state.t('Rejoin Streak', 'دوبارہ شامل ہوں')
                        : state.t('Join Streak', 'سٹریک میں شامل ہوں'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
