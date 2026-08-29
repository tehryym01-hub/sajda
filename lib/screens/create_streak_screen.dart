import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

class CreateStreakScreen extends StatefulWidget {
  const CreateStreakScreen({super.key});

  @override
  State<CreateStreakScreen> createState() => _CreateStreakScreenState();
}

class _CreateStreakScreenState extends State<CreateStreakScreen> {
  int _selectedDays = 30;
  bool _isShared = false;
  bool _loading = false;
  final _customController = TextEditingController();
  bool _customMode = false;

  final List<int> _presets = [7, 14, 30, 40, 90];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final days = _customMode ? int.tryParse(_customController.text.trim()) ?? _selectedDays : _selectedDays;
    final clamped = days < 3 ? 3 : (days > 365 ? 365 : days);
    setState(() => _loading = true);
    final state = context.read<AppState>();
    final error = _isShared
        ? await state.createSharedStreak(clamped)
        : await state.createPersonalStreak(clamped);
    setState(() => _loading = false);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(state.t('Start a Streak', 'سٹریک شروع کریں'), style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.t('How long is your streak?', 'آپ کی سٹریک کتنی لمبی ہے؟'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _presets.map((days) {
                  final selected = !_customMode && _selectedDays == days;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _customMode = false;
                        _selectedDays = days;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDeep],
                              )
                            : null,
                        color: selected ? null : (isDark ? AppColors.darkSurface : AppColors.lightCard),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? AppColors.primary : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
                          width: selected ? 0 : 1,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                            : null,
                      ),
                      child: Text(
                        '$days ${state.t('Days', 'دن')}',
                        style: TextStyle(
                          color: selected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  setState(() => _customMode = true);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: _customMode
                        ? LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDeep],
                          )
                        : null,
                    color: _customMode ? null : (isDark ? AppColors.darkSurface : AppColors.lightCard),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _customMode ? AppColors.primary : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
                      width: _customMode ? 0 : 1,
                    ),
                  ),
                  child: Text(
                    state.t('Custom', 'اپنی مرضی'),
                    style: TextStyle(
                      color: _customMode ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
                      fontWeight: _customMode ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              if (_customMode) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _customController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: state.t('Enter days (3-365)', 'دن درج کریں (3-365)'),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Text(
                state.t('Who is joining?', 'کون شامل ہو رہا ہے؟'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              const SizedBox(height: 16),
              _SelectionCard(
                isSelected: !_isShared,
                isDark: isDark,
                onTap: () => setState(() => _isShared = false),
                icon: Icons.person_outline_rounded,
                title: state.t('Just Me', 'صرف میں'),
                subtitle: state.t('Personal streak', 'ذاتی سٹریک'),
              ),
              const SizedBox(height: 12),
              _SelectionCard(
                isSelected: _isShared,
                isDark: isDark,
                onTap: () => setState(() => _isShared = true),
                icon: Icons.group_outlined,
                title: state.t('Friends & Family', 'دوست اور خاندان'),
                subtitle: state.t('Shared streak', 'شیر شد سٹریک'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _loading ? null : _create,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: _loading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(state.t('Create Streak', 'سٹریک بنائیں'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;

  const _SelectionCard({
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primaryDeep.withValues(alpha: 0.08)],
                )
              : null,
          color: isSelected ? null : (isDark ? AppColors.darkSurface : AppColors.lightCard),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))]
              : [
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDeep],
                      )
                    : null,
                color: isSelected ? null : AppColors.primaryPill(isDark),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.darkText : AppColors.lightText),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkMuted : AppColors.lightMutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDeep],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
