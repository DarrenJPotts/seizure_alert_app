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
        padding: EdgeInsets.fromLTRB(
          Dimensions.twentyFour,
          Dimensions.twelve,
          Dimensions.twentyFour,
          Dimensions.twentyFour,
        ),
        child: Row(
          children: [
            if (vm.step.value > 0)
              Padding(
                padding: EdgeInsets.only(right: Dimensions.twelve),
                child: OutlinedButton(
                  onPressed: vm.back,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black26),
                    padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.twentyFour,
                        vertical: Dimensions.sixteen),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.black38,
                  padding:
                      EdgeInsets.symmetric(vertical: Dimensions.sixteen),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: vm.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isLast ? vm.finishLabel : vm.nextLabel,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
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
