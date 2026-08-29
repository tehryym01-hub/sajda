import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

class JoinStreakScreen extends StatefulWidget {
  const JoinStreakScreen({super.key});

  @override
  State<JoinStreakScreen> createState() => _JoinStreakScreenState();
}

class _JoinStreakScreenState extends State<JoinStreakScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _inviteData;
  String? _error;

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
      _error = null;
      _inviteData = null;
    });
    final data = await context.read<AppState>().getSharedStreakInvite(code);
    setState(() {
      _loading = false;
      _inviteData = data;
      if (data == null) _error = context.read<AppState>().t('Invalid or expired invite', 'غلط یا ختم ہو چکا انوائٹ');
    });
  }

  Future<void> _join() async {
    final code = _controller.text.trim().toUpperCase();
    setState(() => _loading = true);
    final error = await context.read<AppState>().joinSharedStreak(code);
    setState(() => _loading = false);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else if (mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
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
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDeep],
                        ),
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
                  onPressed: _loading ? null : _lookup,
                  icon: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(Icons.search_rounded, color: Colors.white),
                  label: Text(state.t('Lookup', 'تلاش کریں')),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.danger.withValues(alpha: 0.1),
                        AppColors.danger.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_error!, style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              ],
              if (_inviteData != null) ...[
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.08),
                        AppColors.primaryDeep.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8)),
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
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryDeep],
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(14)),
                              ),
                              child: Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _inviteData!['sharedStreak']?['title']?.toString() ?? state.t('Salah Streak', 'صلاح سٹریک'),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          icon: Icons.person_outline_rounded,
                          label: state.t('Created by', 'بنایا'),
                          value: _inviteData!['sharedStreak']?['creatorName']?.toString() ?? 'Unknown',
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: state.t('Progress', 'پrogрес'),
                          value: '${_inviteData!['sharedStreak']?['currentDay'] ?? 0} / ${_inviteData!['sharedStreak']?['goalDays'] ?? 0} ${state.t('days', 'دن')}',
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.people_outline_rounded,
                          label: state.t('Members', 'ارکان'),
                          value: '${_inviteData!['sharedStreak']?['memberCount'] ?? 0} / ${_inviteData!['sharedStreak']?['maxMembers'] ?? 10}',
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _loading ? null : _join,
                            icon: _loading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Icon(Icons.group_add_rounded, color: Colors.white),
                            label: Text(state.t('Join Streak', 'سٹریک میں شامل ہوں'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
        ),
      ],
    );
  }
}
