import 'dart:math' as math;

import 'package:flutter/material.dart';

// ============================================================
// Sajda — New Design System (Design 3 inspired)
// ============================================================

class AppColors {
  // ── Primary ──────────────────────────────────────────────
  static const primary = Color(0xFF00BFA5);
  static const primaryDark = Color(0xFF00897B);
  static const primaryDeep = Color(0xFF00695C);
  static const primaryLight = Color(0xFFE0F7F3);

  // ── Accent — Pastel Cards ────────────────────────────────
  static const pastelPink = Color(0xFFFFB3BA);
  static const pastelGreen = Color(0xFFBAFFC9);
  static const pastelBlue = Color(0xFFBAE1FF);
  static const pastelYellow = Color(0xFFFFFFBA);
  static const pastelPurple = Color(0xFFE8BAFF);
  static const pastelOrange = Color(0xFFFFD9BA);

  // ── Gradient Colors ──────────────────────────────────────
  static const gradientTeal = [Color(0xFF00BFA5), Color(0xFF00897B)];
  static const gradientMint = [Color(0xFFE0F7F3), Color(0xFFF0FFFE)];
  static const gradientSunset = [Color(0xFFFFB3BA), Color(0xFFFFD9BA)];
  static const gradientOcean = [Color(0xFFBAE1FF), Color(0xFFE0F7F3)];

  // ── Light Mode ───────────────────────────────────────────
  static const lightBackground = Color(0xFFF8FFFE);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF1A1A2E);
  static const lightSecondaryText = Color(0xFF6B7280);
  static const lightMutedText = Color(0xFF9CA3AF);
  static const lightBorder = Color(0xFFE5E7EB);
  static const lightDivider = Color(0xFFF3F4F6);

  // ── Dark Mode ────────────────────────────────────────────
  static const darkBackground = Color(0xFF0B1210);
  static const darkSurface = Color(0xFF16201D);
  static const darkSurfaceAlt = Color(0xFF1E2B27);
  static const darkText = Color(0xFFF0FFF8);
  static const darkMuted = Color(0xFF9AABA4);

  // ── Neutral ──────────────────────────────────────────────
  static const background = Color(0xFFF8FFFE);
  static const surface = Colors.white;
  static const textDark = Color(0xFF1A1A2E);
  static const textMuted = Color(0xFF6B7280);
  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);

  // ── Shadow ───────────────────────────────────────────────
  static const shadow = Color(0x1400BFA5);
  static const shadowSoft = Color(0x0A00BFA5);

  // ── Dark/Light adaptive helpers ───────────────────────────
  static Color primaryPill(bool isDark) => isDark ? primary.withValues(alpha: 0.18) : primaryLight;
  static Color surfaceCard(bool isDark) => isDark ? darkSurface : lightCard;
  static Color borderLine(bool isDark) => isDark ? darkSurfaceAlt : lightBorder;
  static Color textMain(bool isDark) => isDark ? darkText : lightText;
  static Color textSub(bool isDark) => isDark ? darkMuted : lightSecondaryText;
}

class AppTheme {
  static ThemeData light() => _base(Brightness.light);

  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      secondary: AppColors.primaryDark,
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
    );

    final baseText = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedText = isDark ? AppColors.darkMuted : AppColors.lightMutedText;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        foregroundColor: baseText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleSpacing: 4,
        titleTextStyle: TextStyle(
          color: baseText,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.lightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightCard,
        indicatorColor: isDark ? AppColors.primary.withValues(alpha: 0.2) : AppColors.primaryLight,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        height: 76,
        elevation: 8,
        shadowColor:
            isDark ? Colors.black54 : AppColors.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : mutedText,
            size: selected ? 26 : 24,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF9FAFB),
        hintStyle: TextStyle(color: mutedText, fontSize: 14),
        labelStyle:
            TextStyle(color: mutedText, fontWeight: FontWeight.w500),
        prefixIconColor: mutedText,
        suffixIconColor: mutedText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? AppColors.darkSurfaceAlt
                : const Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: isDark
                ? AppColors.darkSurfaceAlt
                : const Color(0xFFD1E7DD),
          ),
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? AppColors.darkSurfaceAlt : AppColors.lightText,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF3F4F6),
        selectedColor: AppColors.primary,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: TextStyle(
          color: isDark ? AppColors.darkText : AppColors.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: mutedText,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: mutedText,
        ),
        dividerColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: baseText,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14.5,
          color: baseText,
          height: 1.5,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurface : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: mutedText.withValues(alpha: 0.4),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: isDark ? AppColors.darkSurfaceAlt : AppColors.primaryLight,
        circularTrackColor: isDark ? AppColors.darkSurfaceAlt : AppColors.primaryLight,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: baseText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      textTheme: TextTheme(
        displaySmall: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: baseText,
          height: 1.2,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: baseText,
          height: 1.3,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: baseText,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: baseText,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: baseText,
          height: 1.35,
        ),
        titleSmall: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: baseText,
          height: 1.3,
        ),
        bodyLarge: TextStyle(
          fontSize: 15.5,
          color: baseText,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: baseText,
          height: 1.55,
        ),
        bodySmall: TextStyle(
          fontSize: 12.5,
          color: mutedText,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: baseText,
        ),
      ),
    );
  }
}

// ============================================================
// Reusable Widgets
// ============================================================

/// Soft elevated card with optional gradient.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final Border? border;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.radius = 20,
    this.border,
    this.shadows,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ??
            (isDark ? AppColors.darkSurface : AppColors.lightCard),
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border ??
            Border.all(
              color: isDark
                  ? AppColors.darkSurfaceAlt
                  : AppColors.lightBorder,
            ),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: isDark
                    ? Colors.black26
                    : AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

/// Gradient hero panel (prayer card, headers).
class HeroPanel extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool withPattern;

  const HeroPanel({
    super.key,
    required this.child,
    this.colors,
    this.padding = const EdgeInsets.all(20),
    this.radius = 26,
    this.withPattern = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors ?? AppColors.gradientTeal,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: withPattern
          ? Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _GeometricPatternPainter()),
                ),
                child,
              ],
            )
          : child,
    );
  }
}

/// Decorative geometric pattern for hero panels.
class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const side = 54.0;
    for (double x = -side; x < size.width + side; x += side * 1.6) {
      for (double y = -side; y < size.height + side; y += side * 1.6) {
        final center = Offset(x, y);
        final path = Path();
        for (var i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          final r = (i.isEven ? side * 0.52 : side * 0.26);
          final px = center.dx + r * math.cos(angle);
          final py = center.dy + r * math.sin(angle);
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Section title with accent bar.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppColors.gradientTeal,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!, // ignore: use_null_aware_elements
      ],
    );
  }
}

/// Rounded icon tile with pastel background.
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Pastel colored feature card (for home grid).
class PastelCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const PastelCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill chip for horizontal filters.
class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurfaceAlt : Colors.white),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark
                    ? AppColors.darkSurfaceAlt
                    : const Color(0xFFE5E7EB)),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (isDark ? AppColors.darkText : AppColors.textDark),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Circular progress ring (for streak, tasbeeh).
class ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 10,
    this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = color ?? AppColors.primary;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: strokeWidth,
            backgroundColor: ringColor.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(ringColor),
            strokeCap: StrokeCap.round,
          ),
          if (child != null)
            Center(child: child),
        ],
      ),
    );
  }
}

class AppLoader extends StatelessWidget {
  final double size;
  const AppLoader({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final String message;
  const EmptyView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.danger : AppColors.primaryDark,
    ),
  );
}

