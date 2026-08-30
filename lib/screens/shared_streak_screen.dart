import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'invite_share_card.dart';

class SharedStreakScreen extends StatelessWidget {
  const SharedStreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shared = state.sharedStreak;
    final members = state.sharedMembers;

    if (shared == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Center(
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
                    child: Icon(Icons.group_outlined, size: 56, color: AppColors.primary.withValues(alpha: 0.7)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  context.read<AppState>().t('No shared streak yet', 'ابھی تک کوئی شیر شد سٹریک نہیں'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeMembers = members.where((m) => m.isActive).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(shared.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '${shared.currentDay}/${shared.goalDays}',
                      style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                    ),
                    Text(
                      context.read<AppState>().t('days completed', 'دن مکمل'),
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primaryDeep.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.people_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    context.read<AppState>().t('Members', 'ارکان'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...activeMembers.map((m) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDeep],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        m.displayName.isNotEmpty ? m.displayName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(m.displayName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primaryDeep.withValues(alpha: 0.08)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${m.currentDay} ${context.read<AppState>().t('days', 'دن')}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 20),
            if (shared.status == 'active')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final appUrl = 'https://play.google.com/store/apps/details?id=com.sajda.dataplus';
                        if (shared.inviteCode.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.read<AppState>().t('No invite code available', 'انوائٹ کوڈ دستیاب نہیں'))),
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
                              creatorName: context.read<AppState>().displayName,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.share_rounded, color: AppColors.primary),
                      label: Text(context.read<AppState>().t('Share Invite', 'انوائٹ شیئر کریں'), style: TextStyle(color: AppColors.primary)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(context.read<AppState>().t('Leave Streak?', 'سٹریک چھوڑیں؟'), style: const TextStyle(fontWeight: FontWeight.w800)),
                            content: Text(context.read<AppState>().t('Are you sure you want to leave?', 'کیا آپ واقعی چھوڑنا چاہتے ہیں؟')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.read<AppState>().t('Cancel', 'منسوخ'))),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.read<AppState>().t('Leave', 'چھوڑیں'), style: const TextStyle(color: AppColors.danger))),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          final error = await context.read<AppState>().leaveSharedStreak(shared.id);
                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                          } else if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      icon: Icon(Icons.exit_to_app_rounded, color: AppColors.danger),
                      label: Text(context.read<AppState>().t('Leave', 'چھوڑیں'), style: TextStyle(color: AppColors.danger)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}





