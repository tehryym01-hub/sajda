import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) { debugPrint('launchUrl: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(state.t('Support', 'مدد'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDeep],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 12),
                Text(AppConfig.appName, style: Theme.of(context).textTheme.titleLarge),
                Text(AppConfig.appTagline, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _tile(
            context,
            Icons.email_outlined,
            state.t('Email Us', 'ہمیں ای میل کریں'),
            state.t('We reply within 24 hours', 'ہم 24 گھنٹوں میں جواب دیتے ہیں'),
            () => _launch('mailto:support@sajdadailyathan.site?subject=DAILY%20ATHAN%20Support'),
          ),
          _tile(
            context,
            Icons.rate_review_outlined,
            state.t('Rate the App', 'ایپ کو ریٹ کریں'),
            state.t('Share your feedback on the store', 'اسٹور پر اپنی رائے دیں'),
            () async {
              final review = InAppReview.instance;
              try {
                await review.requestReview();
              } catch (e) { debugPrint('requestReview: $e'); }
            },
          ),
          _tile(
            context,
            Icons.share_outlined,
            state.t('Share SAJDA: DAILY ATHAN & QIBLA', 'ڈیلی اذان شیئر کریں'),
            state.t('Help others discover the app', 'دوسروں کو ایپ سے متعارف کروائیں'),
            () => _launch('https://play.google.com/store/apps/details?id=com.sajda.dataplus'),
          ),
          const SizedBox(height: 14),
          Text(
            state.t(
              'JazakAllah Khair for using SAJDA: DAILY ATHAN & QIBLA. May Allah reward you abundantly.',
              'ڈیلی اذان استعمال کرنے کے لیے جزاک اللہ خیر۔ اللہ آپ کو بہترین اجر دے۔',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryPill(isDark).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
            ),
            child: Text(
              state.t(
                'Arabic Matn, Quranic Verses, and Masnoon Duas are strictly in the Public Domain. '
                'Hadith translations are dynamically fetched via open-source APIs (Hadith-API / Quran.com) '
                'for non-commercial educational reference.',
                'عربی متن، قرآنی آیات اور مسنون دعائیں بالکل عوامی ڈومین میں ہیں۔ '
                'حدیث کے ترجمے غیر تجارتی تعلیمی حوالے کے لیے اوپن سورس API (Hadith-API / Quran.com) '
                'سے ڈائنامکلی فچ کیے جاتے ہیں۔',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                height: 1.5,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryPill(isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}





