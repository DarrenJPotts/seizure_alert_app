import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:seizure_app/features/onboarding/widgets/onboarding_bottom_nav.dart';
import 'package:seizure_app/features/onboarding/widgets/onboarding_step_emergency_contact.dart';
import 'package:seizure_app/features/onboarding/widgets/onboarding_step_permissions.dart';
import 'package:seizure_app/features/onboarding/widgets/onboarding_step_your_name.dart';

class OnboardingView extends StatelessWidget {
  OnboardingView({super.key});

  final vm = Get.put(OnboardingViewModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Obx(() => _ProgressBar(
                  current: vm.step.value,
                  total: OnboardingViewModel.totalSteps,
                )),
            Expanded(
              child: PageView(
                controller: vm.pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  OnboardingStepYourName(vm: vm),
                  OnboardingStepEmergencyContact(vm: vm),
                  OnboardingStepPermissions(vm: vm),
                ],
              ),
            ),
            OnboardingBottomNav(vm: vm),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          Dimensions.twentyFour, Dimensions.sixteen, Dimensions.twentyFour, 0),
      child: Row(
        spacing: Dimensions.eight,
        children: List.generate(
          total,
          (i) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              decoration: BoxDecoration(
                color: i <= current ? Colors.black : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
