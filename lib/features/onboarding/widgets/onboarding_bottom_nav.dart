import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/onboarding/view_models/onboarding_view_model.dart';

class OnboardingBottomNav extends StatelessWidget {
  const OnboardingBottomNav({super.key, required this.vm});

  final OnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLast = vm.isLastStep;

      return Padding(
        padding: const EdgeInsets.fromLTRB(
          Dimensions.twentyFour,
          Dimensions.twelve,
          Dimensions.twentyFour,
          Dimensions.twentyFour,
        ),
        child: Row(
          children: [
            if (vm.step.value > 0)
              Padding(
                padding: const EdgeInsets.only(right: Dimensions.twelve),
                child: OutlinedButton(
                  onPressed: vm.back,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.ink,
                    side: BorderSide(
                      color: context.ink.withValues(alpha: 0.26),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.twentyFour,
                      vertical: Dimensions.sixteen,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.design.cardRadius,
                      ),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
            Expanded(
              child: ElevatedButton(
                onPressed: vm.isLoading.value
                    ? null
                    : isLast
                    ? vm.finish
                    : vm.next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.ink,
                  foregroundColor: context.paper,
                  disabledBackgroundColor: context.ink.withValues(alpha: 0.38),
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.sixteen,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      context.design.cardRadius,
                    ),
                  ),
                ),
                child: vm.isLoading.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: context.paper,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isLast ? vm.finishLabel : vm.nextLabel,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: context.paper,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
