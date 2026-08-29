import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/map_location_picker_screen.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _page = PageController();
  int _index = 0;
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  static const _pages = [
    _OnboardPage(
      icon: Icons.mosque_outlined,
      title: 'Assalamu Alaikum',
      subtitle: 'Welcome to Sajda\nYour daily companion for prayer & Quran',
      cta: 'Get Started',
      gradientColors: [Color(0xFF00BFA5), Color(0xFF00897B)],
      bgColor: Color(0xFFF0FFFE),
      iconBg: Color(0xFFE0F7F3),
    ),
    _OnboardPage(
      icon: Icons.access_time_rounded,
      title: 'Never Miss a Prayer',
      subtitle: 'Accurate prayer times for your location\nwith beautiful Adhan notifications',
      cta: 'Next',
      gradientColors: [Color(0xFFBAE1FF), Color(0xFF89CFF0)],
      bgColor: Color(0xFFF0F8FF),
      iconBg: Color(0xFFE0F0FF),
    ),
    _OnboardPage(
      icon: Icons.menu_book_outlined,
      title: 'Read & Memorize Quran',
      subtitle: 'Explore all 114 Surahs with translations\nTrack your reading progress',
      cta: 'Next',
      gradientColors: [Color(0xFFBAFFC9), Color(0xFF7DD3A0)],
      bgColor: Color(0xFFF0FFF4),
      iconBg: Color(0xFFE0FFE8),
    ),
    _OnboardPage(
      icon: Icons.local_fire_department_outlined,
      title: 'Build Your Streak',
      subtitle: 'Stay consistent with daily prayers\nCompete with friends in shared streaks',
      cta: 'Next',
      gradientColors: [Color(0xFFFFB3BA), Color(0xFFFF8A95)],
      bgColor: Color(0xFFFFF0F2),
      iconBg: Color(0xFFFFE0E5),
    ),
    _OnboardPage(
      icon: Icons.explore_outlined,
      title: 'Find Your Qibla',
      subtitle: 'Precise Qibla direction with compass\nNever miss the direction again',
      cta: "Bismillah, Let's Begin",
      gradientColors: [Color(0xFFE8BAFF), Color(0xFFC77DFF)],
      bgColor: Color(0xFFF8F0FF),
      iconBg: Color(0xFFF0E0FF),
    ),
  ];

  static const int _mapPageIndex = 5;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.06).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    _page.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _page.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else if (_index == _pages.length - 1) {
      setState(() => _index = _mapPageIndex);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final state = context.read<AppState>();
    await state.setOnboardingDone();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (_index == _mapPageIndex) {
      return MapLocationPickerScreen(onLocationConfirmed: _finish);
    }

    final p = _pages[_index];
    return Scaffold(
      backgroundColor: p.bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle decorative circles
          Positioned(
            top: -80,
            right: -60,
            child: _DecorativeCircle(
              color: p.gradientColors.first.withValues(alpha: 0.08),
              size: 200,
            ),
          ),
          Positioned(
            bottom: 120,
            left: -40,
            child: _DecorativeCircle(
              color: p.gradientColors.last.withValues(alpha: 0.06),
              size: 160,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(
                        state.t('Skip', 'چھوڑیں'),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _page,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _OnboardPageView(
                      page: _pages[i],
                      pulse: _pulseAnim,
                    ),
                  ),
                ),
                // Dots + Next button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    children: [
                      // Dots
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: List.generate(
                            _pages.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: i == _index ? 28 : 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: i == _index
                                    ? p.gradientColors.first
                                    : AppColors.lightBorder,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Next button
                      GestureDetector(
                        onTap: _next,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: p.gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: p.gradientColors.first
                                    .withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.gradientColors.first,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        elevation: 0,
                        shadowColor: p.gradientColors.first.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        p.cta,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page Data ──────────────────────────────────────────────
class _OnboardPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String cta;
  final List<Color> gradientColors;
  final Color bgColor;
  final Color iconBg;

  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.gradientColors,
    required this.bgColor,
    required this.iconBg,
  });
}

// ── Page View ──────────────────────────────────────────────
class _OnboardPageView extends StatelessWidget {
  final _OnboardPage page;
  final Animation<double> pulse;
  const _OnboardPageView({required this.page, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with pulse animation
          ScaleTransition(
            scale: pulse,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: page.iconBg,
                boxShadow: [
                  BoxShadow(
                    color: page.gradientColors.first.withValues(alpha: 0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(
                page.icon,
                size: 64,
                color: page.gradientColors.first,
              ),
            ),
          ),
          const SizedBox(height: 44),
          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1.3,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          // Subtitle
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textMuted,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Decorative Circle ──────────────────────────────────────
class _DecorativeCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _DecorativeCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

