import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/dependency_injection.dart';
import 'package:seizure_app/firebase_options.dart';

import 'core/controllers/theme_controller/theme_controller.dart';
import 'core/routes/app_routes.dart';
import 'core/themes/app_theme.dart';

Future<void> _setUpFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) return;

  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  } catch (error) {
    // Keep the emergency UI available during a transient attestation failure.
    // Callable endpoints remain protected and will reject requests without a
    // valid token.
    debugPrint('Firebase App Check activation failed: $error');
  }
}

Future<void> _setUpCrashReporting() async {
  if (kIsWeb) return;

  try {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
  } catch (error) {
    // Crash reporting must never prevent the emergency interface from opening.
    debugPrint('Firebase Crashlytics setup failed: $error');
  }
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _setUpFirebase();
  await _setUpCrashReporting();

  await initDependencyInjection();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = ThemeController.instance();

    // Obx rebuilds only this subtree when the preference changes. GetMaterialApp
    // keeps its element (same widget type), so the navigator and its stack
    // survive a theme switch.
    return Obx(
      () => GetMaterialApp(
        enableLog: true,
        title: 'Seizure alert',
        debugShowCheckedModeBanner: false,
        opaqueRoute: true,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        // `resolvedMode`, not `themeMode`: the user's choice is stored, but it
        // stays clamped to light until the widget sweep lands. See
        // ThemeController.darkModeAvailable.
        themeMode: themeController.resolvedMode,
        initialRoute: initialRoute,
        getPages: routes,
        defaultTransition: Transition.cupertino,
        transitionDuration: Duration(milliseconds: 250),
        textDirection: TextDirection.ltr,
      ),
    );
  }
}
