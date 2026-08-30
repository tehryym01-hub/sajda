import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/legal_screen.dart';
import '../screens/location_setup_screen.dart';
import '../services/api_client.dart';
import '../services/prayer_notification_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  Future<void> _toggleNotifications(BuildContext context, bool value) async {
    final state = context.read<AppState>();
    if (value) {
      final granted = await PrayerNotificationService.instance.requestPermissions();
      if (!context.mounted) return;
      if (!granted) {
        showAppSnack(
          context,
          state.t('Notifications permission needed to enable prayer alerts', 'نماز کے الرٹس کے لیے نوٹیفکیشن کی اجازت درکار ہے'),
          error: true,
        );
        return;
      }
      await state.setNotificationsEnabled(true);
      try {
        final times = await ApiClient.instance.getPrayerTimesFor(state, useCache: false);
        await PrayerNotificationService.instance
            .scheduleAll(times.prayers, isUrdu: state.isUrdu, prayerModes: state.prayerNotificationModes);
      } catch (e) {
        if (!context.mounted) return;
        showAppSnack(context, state.t('Could not schedule alerts: ${e.toString()}', 'الرٹس شیڈول نہیں ہوئے: ${e.toString()}'), error: true);
      }
    } else {
      await state.setNotificationsEnabled(false);
      await PrayerNotificationService.instance.cancelAll();
    }
    if (!context.mounted) return;
    showAppSnack(context, value
        ? state.t('Azan alerts enabled for all prayers', 'تمام نمازوں کے لیے اذان کے الرٹس فعال کر دیے گئے')
        : state.t('Prayer alerts disabled', 'نماز کے الرٹس بند کر دیے گئے'));
  }

  Future<void> _setPrayerMode(BuildContext context, String prayer, String mode) async {
    final state = context.read<AppState>();
    await state.setPrayerNotificationMode(prayer, mode);
    if (!context.mounted) return;
    try {
      final times = await ApiClient.instance.getPrayerTimesFor(state, useCache: false);
      await PrayerNotificationService.instance
          .scheduleAll(times.prayers, isUrdu: state.isUrdu, prayerModes: state.prayerNotificationModes);
    } catch (_) {}
  }

  void _showLanguagePicker(BuildContext context, AppState state) {
    final currentLang = state.language;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).viewPadding.bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                state.t('Select Language', 'زبان منتخب کریں'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ...AppStrings.supportedLanguages.map((l) {
                final isSelected = l.code == currentLang;
                return ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.primaryPill(Theme.of(ctx).brightness == Brightness.dark),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.language_rounded,
                      color: isSelected ? AppColors.primary : AppColors.primaryDark,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    l.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    state.setLanguage(l.code);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(state.t('Settings', 'ترتیبات')), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _SectionHeader(icon: Icons.language_rounded, title: state.t('Language', 'زبان')),
          const SizedBox(height: 10),
          _SettingsCard(
            child: _NavigationTile(
              icon: Icons.language_rounded,
              title: state.t('Language', 'زبان'),
              subtitle: AppStrings.supportedLanguages.firstWhere((l) => l.code == state.language, orElse: () => AppStrings.supportedLanguages.first).name,
              onTap: () => _showLanguagePicker(context, state),
            ),
          ),

          const SizedBox(height: 20),
          _SectionHeader(icon: Icons.notifications_rounded, title: state.t('Notifications', 'نوٹیفکیشنز')),
          const SizedBox(height: 10),
          _SettingsCard(
            child: Column(children: [
              _SwitchTile(
                icon: Icons.mosque_rounded,
                title: state.t('Prayer Alerts', 'نماز کے الرٹس'),
                subtitle: state.t('Azan at every prayer time', 'ہر نماز کے وقت اذان'),
                value: state.notificationsEnabled,
                onChanged: (v) => _toggleNotifications(context, v),
              ),
               if (state.notificationsEnabled) ...[
                 const Divider(height: 1, indent: 16, endIndent: 16),
                 const SizedBox(height: 6),
                ..._prayerNames.map((p) {
                  final mode = state.prayerNotificationModes[p] ?? 'full';
                  return _PrayerModeTile(
                    prayer: p,
                    prayerUr: state.t(p, AppStrings.prayerNames[p] ?? p),
                    mode: mode,
                    fullLabel: state.t('Full Azan', 'پورے اذان'),
                    silentLabel: state.t('Silent', 'چپ چاپ'),
                    onChanged: (m) => _setPrayerMode(context, p, m),
                  );
                }),
                 const SizedBox(height: 6),
              ],
            ]),
          ),

          const SizedBox(height: 20),
          _SectionHeader(icon: Icons.location_on_rounded, title: state.t('Location', 'مقام')),
          const SizedBox(height: 10),
          _SettingsCard(
            child: _NavigationTile(
              icon: Icons.location_on_outlined,
              title: state.t('Location', 'مقام'),
              subtitle: '${state.displayCityName}, ${state.displayCountryName}',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocationSetupScreen())),
            ),
          ),

          const SizedBox(height: 20),
          _SectionHeader(icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, title: state.t('Appearance', 'ظاہری')),
          const SizedBox(height: 10),
          _SettingsCard(
            child: _SwitchTile(
              icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              title: state.t('Dark Mode', 'ڈارک موڈ'),
              subtitle: state.t('Toggle dark/light theme', 'ڈارک/لائٹ تھیم تبدیل کریں'),
              value: state.darkMode,
              onChanged: (_) => state.toggleDarkMode(),
            ),
          ),

          const SizedBox(height: 20),
          _SectionHeader(icon: Icons.privacy_tip_rounded, title: state.t('Privacy & Data', 'رازداری اور ڈیٹا')),
          const SizedBox(height: 10),
          _SettingsCard(
            child: Column(children: [
              _NavigationTile(
                icon: Icons.info_outline_rounded,
                title: state.t('Data Collection Notice', 'ڈیٹا جمع کرنے کی اطلاع'),
                subtitle: state.t('What data we collect', 'ہم کون سا ڈیٹا جمع کرتے ہیں'),
                onTap: () => _showDataCollectionNotice(context, state),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _NavigationTile(
                icon: Icons.delete_forever_rounded,
                title: state.t('Delete My Data', 'میرا ڈیٹا حذف کریں'),
                subtitle: state.t('Request data deletion', 'ڈیٹا حذف کرنے کی درخواست'),
                onTap: () => _confirmDeleteData(context, state),
              ),
            ]),
          ),

          const SizedBox(height: 20),
          _SectionHeader(icon: Icons.gavel_rounded, title: state.t('Legal', 'قانونی')),
          const SizedBox(height: 10),
          _SettingsCard(
            child: _NavigationTile(
              icon: Icons.gavel_rounded,
              title: state.t('Legal & Attributions', 'قانونی اور تشریحات'),
              subtitle: state.t('Licenses, credits & policies', 'لائسنس، کریڈٹس اور پالیسیز'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LegalScreen())),
            ),
          ),
        ],
      ),
    );
  }

  void _showDataCollectionNotice(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(state.t('Data Collection Notice', 'ڈیٹا جمع کرنے کی اطلاع')),
        content: SingleChildScrollView(
          child: Text(
            state.t(
              'We collect the following data to provide our services:\n\n'
              '• Anonymous device identifier (for app functionality)\n'
              '• Location data (for Qibla direction and prayer times)\n'
              '• Display name (optional, for streak features)\n'
              '• Prayer completion data (for streak tracking)\n'
              '• Notification preferences\n'
              '• Language preferences\n\n'
              'This data is used solely to provide prayer times, Qibla direction, and streak features. '
              'We do not sell or share your data with third parties for advertising purposes.',
              'ہم درج ذیل ڈیٹا اپنی خدمات فراہم کرنے کے لیے جمع کرتے ہیں:\n\n'
              '• گمنام ڈیوائس شناختی نمبر (ایپ کی کارکردگی کے لیے)\n'
              '• مقام کا ڈیٹا (قبلہ کی سمت اور نماز کے اوقات کے لیے)\n'
              '• نام (اختیاری، سٹریک خصوصیات کے لیے)\n'
              '• نماز مکمل ہونے کا ڈیٹا (سٹریک ٹریکنگ کے لیے)\n'
              '• نوٹیفکیشن ترجیحات\n'
              '• زبان کی ترجیحات\n\n'
              'یہ ڈیٹا صرف نماز کے اوقات، قبلہ کی سمت، اور سٹریک کی خصوصیات فراہم کرنے کے لیے استعمال کیا جاتا ہے۔ '
              'ہم آپ کا ڈیٹا اشتہاراتی مقاصد کے لیے فروخت یا تیسروں کے ساتھ شیئر نہیں کرتے۔',
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(state.t('OK', 'ٹھیک ہے')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteData(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_forever_rounded, color: Colors.red, size: 48),
        title: Text(state.t('Delete My Data?', 'میرا ڈیٹا حذف کریں؟')),
        content: Text(
          state.t(
            'This will delete all your local data including:\n\n'
            '• Streak data\n'
            '• Prayer completion history\n'
            '• Notification preferences\n'
            '• Language settings\n'
            '• Location settings\n\n'
            'This action cannot be undone.',
            'اس سے آپ کا تمام مقامی ڈیٹا حذف ہو جائے گا بشمول:\n\n'
            '• سٹریک ڈیٹا\n'
            '• نماز مکمل ہونے کی تاریخ\n'
            '• نوٹیفکیشن ترجیحات\n'
            '• زبان کی ترتیبات\n'
            '• مقام کی ترتیبات\n\n'
            'یہ عمل واپس نہیں کیا جا سکتا۔',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(state.t('Cancel', 'منسوخ')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteAllData(context, state);
            },
            child: Text(state.t('Delete', 'حذف کریں')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData(BuildContext context, AppState state) async {
    try {
      if (state.isAuthenticated) {
        final response = await ApiClient.instance.deleteAccount(state);
      }
      await state.logout();
      state.clearStreak();
      if (!context.mounted) return;
      showAppSnack(context, state.t('All data deleted successfully', 'تمام ڈیٹا کامیابی سے حذف ہو گیا'));
    } catch (e) {
      await state.logout();
      state.clearStreak();
      if (!context.mounted) return;
      showAppSnack(context, state.t('All data deleted successfully', 'تمام ڈیٹا کامیابی سے حذف ہو گیا'));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cs.onSurface, letterSpacing: -0.2)),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: child),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
              ]),
            ),
            Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _NavigationTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 22),
          ],
        ),
      ),
    );
  }
}

class _PrayerModeTile extends StatelessWidget {
  final String prayer;
  final String prayerUr;
  final String mode;
  final String fullLabel;
  final String silentLabel;
  final ValueChanged<String> onChanged;
  const _PrayerModeTile({
    required this.prayer,
    required this.prayerUr,
    required this.mode,
    required this.fullLabel,
    required this.silentLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconData = _prayerIcon(prayer);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(prayerUr, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
              Text(prayer, style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModeChip(
                  label: fullLabel,
                  selected: mode == 'full',
                  onTap: () => onChanged('full'),
                ),
                _ModeChip(
                  label: silentLabel,
                  selected: mode == 'silent',
                  onTap: () => onChanged('silent'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _prayerIcon(String p) {
    switch (p) {
      case 'Fajr':
        return Icons.wb_twilight_rounded;
      case 'Dhuhr':
        return Icons.wb_sunny_rounded;
      case 'Asr':
        return Icons.wb_cloudy_rounded;
      case 'Maghrib':
        return Icons.brightness_3_rounded;
      case 'Isha':
        return Icons.bedtime_rounded;
      default:
        return Icons.mosque_rounded;
    }
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
