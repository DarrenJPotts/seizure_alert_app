import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:seizure_app/features/onboarding/widgets/onboarding_field.dart';

class OnboardingStepEmergencyContact extends StatelessWidget {
  const OnboardingStepEmergencyContact({super.key, required this.vm});

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
              Text('Emergency contact',
                  style: Theme.of(context).textTheme.titleMedium),
              Text(
                'This person will be notified immediately if you send an SOS or Heads Up.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black54),
              ),
            ],
          ),
          OnboardingField(
            label: 'Their name',
            controller: vm.contactNameController,
            hint: 'e.g. Jane Smith',
          ),
          OnboardingField(
            label: 'Their phone number',
            controller: vm.contactPhoneController,
            hint: '+27 82 123 4567',
            keyboardType: TextInputType.phone,
          ),
          OnboardingField(
            label: 'Relationship (optional)',
            controller: vm.contactRelationController,
            hint: 'e.g. Partner, Parent, Friend',
          ),
        ],
      ),
    );
  }
}
