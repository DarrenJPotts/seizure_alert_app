import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/dependency_injection.dart';
import 'package:seizure_app/firebase_options.dart';

import 'core/routes/app_routes.dart';
import 'core/themes/app_theme.dart';

Future<void> _setUpFirebase() async => await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _setUpFirebase();

  await initDependencyInjection();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      enableLog: true,
      title: 'Seizure alert',
      debugShowCheckedModeBanner: false,
      opaqueRoute: true,
      theme: AppTheme.lightTheme,
      // darkTheme: AppTheme.dark,
      // themeMode: _themeController.themeMode.value,
      initialRoute: initialRoute,
      getPages: routes,
      defaultTransition: Transition.cupertino,
      transitionDuration: Duration(milliseconds: 250),
      textDirection: TextDirection.ltr,
    );
  }
}
