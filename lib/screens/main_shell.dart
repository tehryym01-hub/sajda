import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../services/api_client.dart';
import '../services/ayah_notification_service.dart';
import '../services/dua_notification_service.dart';
import '../services/prayer_checkin_service.dart';
import '../services/prayer_notification_service.dart';
import '../services/wazifa_notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player_bar.dart';
import 'adhkar_screen.dart';
import 'calendar_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'mushaf_screen.dart';
import 'names_screen.dart';
import 'pillars_screen.dart';
import 'qibla_screen.dart';
import 'quran_screen.dart';
import 'settings_screen.dart';
import 'streak_screen.dart';
import 'support_screen.dart';
import 'tasbeeh_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;
  DateTime? _lastBackPress;
  static const _pages = [
    HomeScreen(),
    StreakScreen(),
    TasbeehScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleDailyNotifications(context);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleDailyNotifications(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_index != 0) {
      // If not on home tab, go to home tab
      setState(() => _index = 0);
      return false;
    }
    if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      return false; // Don't exit, show toast
    }
    return true; // Exit app
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Home is always dark; other tabs follow the theme.
    final iconsLight = _index == 0 || isDark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            iconsLight ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            iconsLight ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(index: _index, children: _pages),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16201D) : AppColors.lightCard,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF26352F)
                    : AppColors.lightBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MiniPlayerBar(),
                   NavigationBar(
                     height: 80,
                     backgroundColor: Colors.transparent,
                     elevation: 0,
                     selectedIndex: _index,
                     onDestinationSelected: (i) => setState(() => _index = i),
                     indicatorColor: isDark ? AppColors.primary.withValues(alpha: 0.25) : AppColors.primaryLight,
                     indicatorShape: const RoundedRectangleBorder(
                       borderRadius: BorderRadius.all(Radius.circular(18)),
                     ),
                      destinations: [
                        _tab(
                          Icons.home_outlined,
                          Icons.home_rounded,
                          state.t('Home', 'ہوم'),
                        ),
                        _streakTab(state.t('Streak', 'سٹریک')),
                        _tab(
                          Icons.circle_outlined,
                          Icons.circle,
                          state.t('Tasbeeh', 'تسبیح'),
                        ),
                        _tab(
                          Icons.settings_outlined,
                          Icons.settings_rounded,
                          state.t('Settings', 'ترتیبات'),
                        ),
                      ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _tab(IconData icon, IconData selectedIcon, String label) {
    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      label: label,
    );
  }

  NavigationDestination _streakTab(String label) {
    return NavigationDestination(
      icon: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 24),
      ),
      selectedIcon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 20, offset: Offset(0, 6)),
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 30, offset: Offset(0, 10)),
          ],
        ),
        child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 28),
      ),
      label: label,
    );
  }

  /// Schedules ayat (after Zuhr) notifications
  /// using the actual prayer times for the current location.
  Future<void> _scheduleDailyNotifications(BuildContext context) async {
    final state = context.read<AppState>();
    final tz = state.locationTimezone;
    if (state.duaNotificationsEnabled) {
      await DuaNotificationService.instance.scheduleNext7Days(timezone: tz);
    }
    if (state.wazifaNotificationsEnabled) {
      await WazifaNotificationService.instance.scheduleNext7Days(timezone: tz);
    }

    var zuhr = 13;
    var zuhrMin = 30;
    try {
      final times = await ApiClient.instance.getPrayerTimesFor(state);
      for (final p in times.prayers) {
        final parts = p.time.split(':');
        if (parts.length != 2) continue;
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h == null || m == null) continue;
        if (p.name == 'Dhuhr') {
          zuhr = h;
          zuhrMin = m;
        }
      }
      if (state.notificationsEnabled) {
        await PrayerNotificationService.instance.scheduleAll(
          times.prayers,
          isUrdu: state.isUrdu,
          timezone: tz,
          prayerModes: state.prayerNotificationModes,
        );
      }
      if (state.prayerCheckinEnabled) {
        await PrayerCheckinService.instance.scheduleCheckIns(times.prayers, timezone: tz);
      }
    } catch (e) { debugPrint('scheduleNotifications: $e'); }

    if (state.ayahNotificationsEnabled) {
      await AyahNotificationService.instance
          .scheduleNext7Days(hour: zuhr, minute: zuhrMin + 15, timezone: tz);
    }
  }
}

class MoreItem {
  final String title;
  final String titleUr;
  final IconData icon;
  final Color color;
  final Widget screen;
  const MoreItem({
    required this.title,
    required this.titleUr,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

/// All features not already in the bottom navigation bar.
List<MoreItem> moreItems(BuildContext context) {
  return [
    MoreItem(
      title: 'Al-Quran',
      titleUr: 'قرآن مجید',
      icon: Icons.menu_book_outlined,
      color: const Color(0xFF1B7F5C),
      screen: const QuranScreen(),
    ),
    MoreItem(
      title: 'Mushaf (Pages)',
      titleUr: 'مصحف (صفحات)',
      icon: Icons.auto_stories_outlined,
      color: const Color(0xFF1F618D),
      screen: const MushafScreen(),
    ),
    MoreItem(
      title: 'Pillars of Islam',
      titleUr: 'ارکان اسلام',
      icon: Icons.mosque_outlined,
      color: const Color(0xFF1E8449),
      screen: const PillarsScreen(),
    ),
    MoreItem(
      title: 'Support',
      titleUr: 'مدد',
      icon: Icons.support_outlined,
      color: const Color(0xFF616A6B),
      screen: const SupportScreen(),
    ),
    MoreItem(
      title: 'Adhkar',
      titleUr: 'اذکار',
      icon: Icons.volunteer_activism_outlined,
      color: const Color(0xFF1E8449),
      screen: const AdhkarScreen(),
    ),
    MoreItem(
      title: '99 Names of Allah',
      titleUr: 'اللہ کے 99 نام',
      icon: Icons.star_outline_rounded,
      color: const Color(0xFFD4A937),
      screen: const NamesScreen(),
    ),
    MoreItem(
      title: 'Islamic Calendar',
      titleUr: 'اسلامی کیلنڈر',
      icon: Icons.calendar_month_outlined,
      color: const Color(0xFFC0392B),
      screen: const CalendarScreen(),
    ),
    MoreItem(
      title: 'Qibla Direction',
      titleUr: 'قبلہ کی سمت',
      icon: Icons.explore_rounded,
      color: const Color(0xFFB8860B),
      screen: const QiblaScreen(),
    ),
    MoreItem(
      title: 'Islamic History',
      titleUr: 'اسلامی تاریخ',
      icon: Icons.history_edu_outlined,
      color: const Color(0xFF8E44AD),
      screen: const HistoryScreen(),
    ),
  ];
}
