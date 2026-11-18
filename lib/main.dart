import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/routing/app_router.dart';
import 'core/splash/animated_splash.dart';
import 'core/storage/shared_preferences_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_reveal.dart';
import 'features/auth/presentation/providers/apple_revocation_provider.dart';
import 'features/profile/presentation/providers/reminder_providers.dart';
import 'features/sync/presentation/providers/sync_providers.dart';
import 'features/user/presentation/providers/user_providers.dart';
import 'firebase_options.dart';
import 'shared/widgets/max_width_frame.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Last line of defence: an unexpected error in a widget, a plugin or an
  // un-awaited Future is logged and the app keeps running, instead of a
  // crash or a frozen screen (App Store Review 2.1).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true; // handled: do not crash
  };
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // In test harness or hot-restart edge cases where already initialized
  }
  final prefs = await SharedPreferences.getInstance();

  // Every screen is designed for a portrait phone.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  // Without this, Android draws its own opaque system navigation bar behind
  // the bottom of the screen — visible as a flat panel behind any CTA that
  // sits near the edge (e.g. the onboarding Continue button), independent of
  // whatever Flutter widget is actually there.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      // Leaving these unset lets the engine re-enable the OS's own contrast
      // scrim on resume, which is what kept painting a solid bar behind the
      // nav area even with a transparent color and native-side flags cleared.
      systemNavigationBarContrastEnforced: false,
      statusBarColor: Colors.transparent,
      systemStatusBarContrastEnforced: false,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const CalestheticsApp(),
    ),
  );
}

class CalestheticsApp extends ConsumerWidget {
  const CalestheticsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the OS reminder schedule in step with settings and the plan.
    ref.watch(reminderSyncProvider);
    // Keeps user data in Firestore synced for signed-in accounts; stays 100% offline for guests.
    ref.watch(cloudSyncProvider);
    // iPhone: signs out if the user stopped using Sign in with Apple.
    ref.watch(appleRevocationProvider);
    return _app(ref);
  }

  Widget _app(WidgetRef ref) {
    return MaterialApp.router(
      // Large system text is honoured up to 1.3x; beyond that the fixed-size
      // cards and pills break words mid-way or overflow.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        // A tap on any empty part of the screen closes the keyboard (on
        // phones Flutter does not do this by itself, and the iOS number pad
        // has no Return key). Taps on buttons and fields still go to them.
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          // Tablets/landscape: phone-width centred column (MaxWidthFrame).
          child: SplashHost(
            child: ThemeRevealHost(child: MaxWidthFrame(child: child!)),
          ),
        ),
      ),
      title: 'Calesthetics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (ref.watch(settingsProvider)['themeMode']) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      },
      // The circular reveal (ThemeRevealHost) does the light/dark transition,
      // so the theme itself changes instantly underneath it.
      themeAnimationDuration: Duration.zero,
      themeAnimationCurve: Curves.easeInOutCubic,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
