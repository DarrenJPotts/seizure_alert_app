import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/widgets/onboarding_progress.dart';
import 'package:seizure_app/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:seizure_app/features/onboarding/widgets/onboarding_bottom_nav.dart';
import 'package:seizure_app/features/onboarding/widgets/onboarding_step_consent.dart';
import 'package:seizure_app/features/onboarding/widgets/onboarding_step_emergency_contact.dart';
import 'package:seizure_app/features/onboarding/widgets/onboarding_step_permissions.dart';
import 'package:seizure_app/features/onboarding/widgets/onboarding_step_your_name.dart';

class OnboardingView extends GetView<OnboardingViewModel> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Column(
        children: <Widget>[
          Obx(
            () => OnboardingProgress(
              completed: controller.currentStep.completed,
              total: OnboardingStep.total,
              label: controller.currentStep.label,
            ),
          ),
          Expanded(
            child: PageView(
              controller: controller.pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                OnboardingStepYourName(vm: controller),
                OnboardingStepEmergencyContact(vm: controller),
                OnboardingStepPermissions(vm: controller),
                OnboardingStepConsent(vm: controller),
              ],
            ),
          ),
          OnboardingBottomNav(vm: controller),
          Obx(() {
            if (controller.mode.value != OnboardingMode.preSignup) {
              return SizedBox(height: Dimensions.eight);
            }
            return Padding(
              padding: EdgeInsets.only(bottom: Dimensions.twelve),
              child: TextButton(
                onPressed: controller.goToSignIn,
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text('I already have an account'),
              ),
            );
          }),
        ],
      ),
    ),
  );
}
