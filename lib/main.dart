import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'core/constants/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/router/app_router.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/shared_prefs_service.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
      if (details.stack != null) {
        debugPrintStack(stackTrace: details.stack);
      }
    };

    // 1. Core Firebase and Preferences must be initialized first
    final prefs = await SharedPreferences.getInstance();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Start UI immediately
    runApp(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const InwinApp(),
    ));

    // 3. Background services
    unawaited(_initBackgroundServices());
  }, (error, stackTrace) {
    debugPrint('Uncaught startup error: $error');
    debugPrintStack(stackTrace: stackTrace);
  });
}

Future<void> _initBackgroundServices() async {
  try {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    await Future.wait([
      initializeDateFormatting('fr_FR', null),
      NotificationService.initialize(),
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
    ]);
  } catch (error, stackTrace) {
    debugPrint('Background initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
// Keep non-critical startup work from crashing the app before the
    // debugger attaches.
class InwinApp extends ConsumerWidget {
  const InwinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationSyncProvider);
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'INWIN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
