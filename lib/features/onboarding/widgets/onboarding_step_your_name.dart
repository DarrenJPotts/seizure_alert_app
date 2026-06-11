import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:seizure_app/features/onboarding/widgets/onboarding_field.dart';

class OnboardingStepYourName extends StatelessWidget {
  const OnboardingStepYourName({super.key, required this.vm});

  final OnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Dimensions.twentyFour),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Dimensions.twentyFour,
        children: [
          SizedBox(height: Dimensions.twentyFour),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Dimensions.eight,
            children: [
              Text('About you',
                  style: Theme.of(context).textTheme.titleMedium),
              Text(
                'Your name helps your circle know who needs help.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black54),
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
          OnboardingField(
            label: 'Your phone number',
            controller: vm.phoneController,
            hint: '+27 82 123 4567',
            keyboardType: TextInputType.phone,
            helper: 'Used so contacts with the app can identify you.',
          ),
        ],
      ),
    );
  }
}
