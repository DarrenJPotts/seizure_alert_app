import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/formatters/south_african_phone_input_formatter.dart';
import 'package:seizure_app/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:seizure_app/features/onboarding/widgets/onboarding_field.dart';

class OnboardingStepYourName extends StatelessWidget {
  const OnboardingStepYourName({super.key, required this.vm});

  final OnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.twentyFour),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Dimensions.twentyFour,
        children: [
          const SizedBox(height: Dimensions.twentyFour),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Dimensions.eight,
            children: [
              Text('About you', style: Theme.of(context).textTheme.titleMedium),
              Text(
                'Your name helps your circle know who needs help.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
              ),
            ],
          ),
          OnboardingField(
            label: 'Your name',
            controller: vm.nameController,
            hint: 'Full name',
            autofocus: true,
            onChanged: (_) {},
          ),
          Obx(
            () => OnboardingField(
              label: 'Your phone number',
              controller: vm.phoneController,
              hint: '+27 82 123 4567',
              keyboardType: TextInputType.phone,
              inputFormatters: const <TextInputFormatter>[
                SouthAfricanPhoneInputFormatter(),
              ],
              maxLength: SouthAfricanPhoneInputFormatter.maxLength,
              helper: 'Used so contacts with the app can identify you.',
              errorText: vm.phoneNumberError.value,
              onChanged: (_) => vm.phoneNumberError.value = null,
            ),
          ),
        ],
      ),
    );
  }
}
