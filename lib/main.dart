import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/location_setup_screen.dart';
import 'services/ayah_notification_service.dart';
import 'services/azkar_audio_provider.dart';
import 'services/dua_notification_service.dart';
import 'services/prayer_notification_service.dart';
import 'services/quran_audio_provider.dart';
import 'services/quran_translation_provider.dart';
import 'services/tafsir_provider.dart';
import 'services/wazifa_notification_service.dart';
import 'services/auth_service.dart';
import 'state/app_state.dart';
import 'state/audio_player_state.dart';
import 'theme/app_theme.dart';
import 'config.dart';
import 'widgets/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  await PrayerNotificationService.instance.init();
  await DuaNotificationService.instance.init();
  await WazifaNotificationService.instance.init();
  await AyahNotificationService.instance.init();
  unawaited(_requestAllPermissions());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..load()),
        ChangeNotifierProvider(create: (_) => AudioPlayerState()),
        ChangeNotifierProvider(create: (_) => AzkarAudioProvider()),
        ChangeNotifierProvider(create: (_) => QuranTranslationProvider()),
        ChangeNotifierProvider(create: (_) => TafsirProvider()),
        ChangeNotifierProvider(create: (_) => QuranAudioProvider()),
        Provider(create: (_) => AuthService.instance),
      ],
      child: const SajdaApp(),
    ),
  );
}

class SajdaApp extends StatelessWidget {
  const SajdaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (!state.loaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final isUrdu = state.isUrdu;
    final lang = state.language;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sajda: Daily Athan & Qibla',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
      locale: lang == 'en' ? const Locale('en') : Locale(lang),
      supportedLocales:
          AppStrings.supportedLanguages.map((l) => Locale(l.code)).toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_showSplash) {
      return PopScope(
        canPop: false,
        child: SplashScreen(onDone: () => setState(() => _showSplash = false)),
      );
    }
    if (!state.onboardingDone) {
      return const PopScope(canPop: false, child: OnboardingScreen());
    }
    if (!state.locationConfigured) {
      return const PopScope(canPop: false, child: LocationSetupScreen());
    }
    return const PopScope(canPop: true, child: MainShell());
  }
}

Future<void> _requestAllPermissions() async {
  try {
    await PrayerNotificationService.instance.requestPermissions();
  } catch (_) {}
  try {
    await Geolocator.requestPermission();
  } catch (_) {}
}


