import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/features/splash/widgets/splash_body.dart';

class SplashViewModel extends GetxController {
  static const Duration _minimumDisplay = Duration(milliseconds: 500);

  @override
  void onReady() {
    super.onReady();
    unawaited(_resolveDestination());
  }

  Future<void> _resolveDestination() async {
    final List<Object?> settled = await Future.wait(<Future<Object?>>[
      FirebaseAuth.instance.authStateChanges().first,
      Future<Object?>.delayed(_minimumDisplay),
    ]);

    final User? user = settled.first as User?;

    if (user != null) {
      Get.offAllNamed(AppRoutes.root);
      return;
    }

    Get.offAllNamed(
      AppModeService.instance().onboardingCompleted.value ? AppRoutes.login : AppRoutes.onboarding,
    );
  }
}

class SplashView extends StatelessWidget {
  SplashView({super.key});

  final SplashViewModel viewModel = Get.put(SplashViewModel());

  @override
  Widget build(BuildContext context) => const Scaffold(backgroundColor: Colors.black, body: SplashBody());
}
