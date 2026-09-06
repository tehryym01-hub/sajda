import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as q;

import '../config.dart';
import '../models/models.dart';
import '../services/allah_names.dart';
import '../services/api_client.dart';
import '../services/quran_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'adhkar_screen.dart';
import 'my_streak_screen.dart';
import 'main_shell.dart';
import 'prayer_screen.dart';
import 'qibla_screen.dart';
import 'quran_screen.dart';
import 'streak_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NextPrayerResponse? _next;
  SearchResult? _ayah;
  List<IslamicEvent> _events = [];
  bool _loading = true;
  String? _error;
  Timer? _timer;
  int _nameIndex = -1;

  @override
  void initState() {
    super.initState();
    _load();
    unawaited(_pickName());
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _load(quiet: true),
    );
  }

  Future<void> _pickName() async {
    final idx = await AllahNames.pickFreshIndex();
    if (mounted) setState(() => _nameIndex = idx);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final state = context.read<AppState>();
    try {
      final times = await ApiClient.instance.getPrayerTimesFor(state);
      if (!mounted) return;
      List<IslamicEvent> events = const [];
      try {
        events = await ApiClient.instance.getTodayEvents();
      } catch (_) {}
      setState(() {
        _next = _computeNext(times);
        _events = events;
        _loading = false;
        _error = null;
      });
      QuranService.instance.dailyAyah().then((ayah) {
        if (!mounted) return;
        setState(() => _ayah = ayah);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _gregorianDate(String lang) {
    final now = DateTime.now();
    try {
      return DateFormat('EEEE, d MMMM y', lang).format(now);
    } catch (_) {
      return DateFormat('EEEE, d MMMM y').format(now);
    }
  }

  String _countdown(AppState state, NextPrayerResponse next) {
    final s = next.countdown;
    if (s <= 0) return '--';
    final h = s ~/ 3600;
    final m = ((s % 3600) ~/ 60);
    if (h > 0) {
      final hStr = state.t('h', 'گھنٹے');
      final mStr = state.t('m', 'منٹ');
      return '$h $hStr $m $mStr';
    }
    final mStr = state.t('m', 'منٹ');
    return '$m $mStr';
  }

  NextPrayerResponse _computeNext(PrayerTimesResponse times) {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final prayers =
        times.prayers.where((p) => p.name != 'Sunrise').toList();

    for (final p in prayers) {
      final parts = p.time.split(':');
      if (parts.length != 2) continue;
      final pm = int.tryParse(parts[0]);
      final pMin = int.tryParse(parts[1]);
      if (pm == null || pMin == null) continue;
      final minutes = pm * 60 + pMin;
      if (minutes > nowMinutes) {
        final totalMinutes = minutes - nowMinutes;
        return NextPrayerResponse(
          currentTime: '',
          name: p.name,
          time: p.time,
          totalMinutes: totalMinutes,
          isTomorrow: false,
          countdown: totalMinutes * 60,
          allPrayers: prayers,
          hijri: times.hijri,
        );
      }
    }

    final fajr = prayers.first;
    final parts = fajr.time.split(':');
    final fajrMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final totalMinutes = (24 * 60 - nowMinutes) + fajrMinutes;
    return NextPrayerResponse(
      currentTime: '',
      name: fajr.name,
      time: fajr.time,
      totalMinutes: totalMinutes,
      isTomorrow: true,
      countdown: totalMinutes * 60,
      allPrayers: prayers,
      hijri: times.hijri,
    );
  }

  Future<void> _showQibla() async {
    final state = context.read<AppState>();
    final city = state.city;
    if (city == null) {
      showAppSnack(
        context,
        state.t('Select a city first', 'پہلے شہر منتخب کریں'),
        error: true,
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QiblaScreen()),
    );
  }

  Future<void> _showAllFeatures() async {
    final state = context.read<AppState>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final items = moreItems(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.4,
        maxChildSize: 0.96,
        expand: false,
        builder: (sheetCtx, scrollController) => Container(
          decoration: BoxDecoration(
            color: dark ? AppColors.darkSurface : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.gradientTeal,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.t('All Features', 'تمام خصوصیات'),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        state.t(
                          'Explore everything in one place',
                          'ایک جگہ سب کچھ دریافت کریں',
                        ),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    return PastelCard(
                      title: state.isUrdu ? item.titleUr : item.title,
                      subtitle: '',
                      icon: item.icon,
                      color: item.color,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => item.screen),
                        );
                      },
                    );
                  },
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final lang = state.language;
    final next = _next;
    final nextName = next == null
        ? state.t('Loading...', 'لوڈ ہو رہا ہے...')
        : (lang == 'ur'
            ? AppStrings.prayerNames[next.name] ?? next.name
            : next.name);

    return Scaffold(
      backgroundColor:
          dark ? AppColors.darkBackground : AppColors.lightBackground,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        backgroundColor: dark ? AppColors.darkSurface : Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).viewPadding.top + 8, 20, 0),
                child: Row(
                  children: [
                    // Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryPill(dark),
                        ),
                        child: Image.asset(
                          'assets/app_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.mosque_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Greeting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameIndex >= 0
                                ? kAllahNames[_nameIndex].arabic
                                : state.t('Good Morning', 'صبح بخیر'),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.color,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _nameIndex >= 0
                                ? '${kAllahNames[_nameIndex].urdu} • ${state.displayCityName}'
                                : '${state.displayCityName}, ${state.displayCountryName}',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Prayer times button
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrayerScreen(),
                        ),
                      ),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primaryPill(dark),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.primary,
                          size: 21,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Hero Prayer Card ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: HeroPanel(
                  withPattern: true,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date + City
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 15,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              state.isUrdu
                                  ? state.todayHijriDate.fullWithWeekdayAr
                                  : state.todayHijriDate.fullWithWeekday,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              state.displayCityName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _gregorianDate(state.language),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Next Prayer
                      Text(
                        state.t('NEXT PRAYER', 'اگلی نماز'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              nextName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                          ),
                          Text(
                            next?.time ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Countdown
                      Row(
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _countdown(
                                state,
                                next ??
                                    NextPrayerResponse(
                                      currentTime: '',
                                      name: '',
                                      time: '',
                                      totalMinutes: 0,
                                      isTomorrow: false,
                                      countdown: 0,
                                      allPrayers: [],
                                      hijri: HijriInfo(),
                                    ),
                              ),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (next != null && next.isTomorrow)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                state.t('Tomorrow', 'کل'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Your Streak ──
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _HomeStreakCard(),
              ),
            ),

            // ── Quick Access ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: SectionHeader(
                  title: state.t('Quick Access', 'فوری رسائی'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.95,
                children: [
                  PastelCard(
                    title: state.t('Al-Quran', 'قرآن مجید'),
                    subtitle: state.t('Read the Holy Quran', 'قرآن پاک پڑھیں'),
                    icon: Icons.menu_book_rounded,
                    color: AppColors.primary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QuranScreen()),
                    ),
                  ),
                  PastelCard(
                    title: state.t('Prayer Times', 'نماز کے اوقات'),
                    subtitle:
                        state.t('Timings & Qibla', 'اوقات اور قبلہ'),
                    icon: Icons.schedule_rounded,
                    color: AppColors.pastelBlue,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrayerScreen()),
                    ),
                  ),
                  PastelCard(
                    title: state.t('Adhkar', 'اذکار'),
                    subtitle: state.t(
                      'Morning & Evening Azkar',
                      'صبح و شام کے اذکار',
                    ),
                    icon: Icons.volunteer_activism_outlined,
                    color: AppColors.pastelPurple,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdhkarScreen()),
                    ),
                  ),
                  PastelCard(
                    title: state.t('Qibla', 'قبلہ'),
                    subtitle: state.t(
                      'Direction of Kaaba',
                      'کعبہ کی سمت',
                    ),
                    icon: Icons.explore_rounded,
                    color: AppColors.pastelOrange,
                    onTap: _showQibla,
                  ),
                ],
              ),
            ),

            // ── View All Features ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GestureDetector(
                  onTap: _showAllFeatures,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: dark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: dark
                            ? AppColors.darkSurfaceAlt
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primaryPill(dark),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.grid_view_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.t('View All Features', 'تمام خصوصیات دیکھیں'),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.color,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Ayah of the Day ──
            if (_ayah != null) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: SectionHeader(
                    title: state.t('Ayah of the Day', 'آج کی آیت'),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _ayah!.arabic,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 19,
                            height: 2,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'serif',
                          ),
                        ),
                        if (_ayah!.english.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            _ayah!.english,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color,
                              fontSize: 14.5,
                              height: 1.7,
                            ),
                          ),
                        ],
                        if (_ayah!.urdu.isNotEmpty &&
                            (lang == 'en' || lang == 'ur')) ...[
                          const SizedBox(height: 12),
                          Text(
                            _ayah!.urdu,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color,
                              fontSize: 14.5,
                              height: 1.7,
                            ),
                          ),
                        ],
                        if (_ayah!.urdu.isEmpty && _ayah!.english.isEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            _ayah!.translation(lang),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color,
                              fontSize: 14.5,
                              height: 1.7,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          state.t(
                            '${q.getSurahNameEnglish(_ayah!.surah)} • Ayah ${_ayah!.ayah}',
                            '${q.getSurahNameArabic(_ayah!.surah)} • آیت ${_ayah!.ayah}',
                          ),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // ── Today's Events ──
            if (_events.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: SectionHeader(
                    title: state.t(
                      "Today's Islamic Events",
                      'آج کے اسلامی واقعات',
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                sliver: SliverList.separated(
                  itemCount: _events.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final e = _events[i];
                    return GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primaryPill(dark),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.event_available_rounded,
                              color: AppColors.primary,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.title(lang),
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.color,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (e.description(lang).isNotEmpty)
                                  Text(
                                    e.description(lang),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                      fontSize: 12.5,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            // ── Loading / Error ──
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              )
            else if (_error != null && _events.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: ErrorView(message: _error!, onRetry: _load),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}

/// State-aware streak entry point on the Home screen.
/// Loading → skeleton, active → summary card, ended → create new,
/// none → create CTA. Never shows "create" while membership is loading.
class _HomeStreakCard extends StatelessWidget {
  const _HomeStreakCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final streak = state.streak;
    final todayDone = [
      state.todayProgress['fajr'],
      state.todayProgress['dhuhr'],
      state.todayProgress['asr'],
      state.todayProgress['maghrib'],
      state.todayProgress['isha'],
    ].where((p) => p == true).length;

    final surface = dark ? AppColors.darkSurface : AppColors.lightCard;
    final border = dark ? AppColors.darkSurfaceAlt : AppColors.lightBorder;

    // Skeleton while membership/streak loads (prevents "Create" flash).
    if (!state.isAuthenticated || (streak == null && state.streakLoading)) {
      return Container(
        height: 84,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: state.isAuthenticated
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      state.t('Start your Salah Streak', 'اپنی صلاح سٹریک شروع کریں'),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ).tapTo(const StreakScreen());
    }

    final active = streak != null && (streak.isActive || streak.isPaused);
    final ended = streak != null && streak.hasEnded;
    final memberCount = state.sharedMembers.where((m) => m.isActive).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDeep]),
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: Icon(
              ended ? Icons.emoji_events_rounded : Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active
                      ? (streak.isShared && state.sharedStreak != null
                          ? state.sharedStreak!.title
                          : state.t('Your Streak', 'آپ کی سٹریک'))
                      : ended
                          ? state.t('Streak Ended', 'سٹریک ختم ہو گئی')
                          : state.t('No streak yet', 'ابھی کوئی سٹریک نہیں'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  active
                      ? '🔥 $todayDone/5 ${state.t('today', 'آج')}'
                      : ended
                          ? state.t('Start a new streak', 'نئی سٹریک شروع کریں')
                          : state.t('Build consistency one day at a time', 'ایک دن میں ایک مستقل بنائیں'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: dark ? AppColors.darkMuted : AppColors.lightMutedText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (active && streak.isShared && memberCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_rounded, size: 13, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('$memberCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDeep]),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => active ? const MyStreakScreen() : const StreakScreen(),
                ),
              ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Text(
                    active ? state.t('View', 'دیکھیں') : state.t('Create', 'بنائیں'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _TapTo on Widget {
  Widget tapTo(Widget screen) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
        child: this,
      ),
    );
  }
}
