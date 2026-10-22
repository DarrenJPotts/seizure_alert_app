import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/formatters/south_african_phone_input_formatter.dart';
import 'package:seizure_app/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:seizure_app/features/onboarding/widgets/onboarding_field.dart';

class OnboardingStepEmergencyContact extends StatelessWidget {
  const OnboardingStepEmergencyContact({super.key, required this.vm});

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
              Text(
                'Emergency contact',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'This person will be notified immediately if you send an SOS or Heads Up.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
              ),
            ],
          ),
          Obx(
            () => OnboardingField(
              label: 'Their name',
              controller: vm.contactNameController,
              hint: 'e.g. Jane Smith',
              errorText: vm.contactNameError.value,
              onChanged: (value) {
                vm.contactNameError.value = null;
                vm.onEmergencyContactChanged(value);
              },
            ),
          ),
          Obx(
            () => OnboardingField(
              label: 'Their phone number',
              controller: vm.contactPhoneController,
              hint: '+27 82 123 4567',
              keyboardType: TextInputType.phone,
              inputFormatters: const <TextInputFormatter>[
                SouthAfricanPhoneInputFormatter(),
              ],
              maxLength: SouthAfricanPhoneInputFormatter.maxLength,
              errorText: vm.contactPhoneError.value,
              onChanged: (value) {
                vm.contactPhoneError.value = null;
                vm.onEmergencyContactChanged(value);
              },
            ),
          ),
          OnboardingField(
            label: 'Relationship (optional)',
            controller: vm.contactRelationController,
            hint: 'e.g. Partner, Parent, Friend',
          ),
          Obx(() {
            final bool ready = vm.hasCompleteEmergencyContactDetails.value;
            return Container(
              decoration: BoxDecoration(
                border: context.designBorder,
                borderRadius: BorderRadius.circular(Dimensions.twelve),
              ),
              child: SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.sixteen,
                  vertical: Dimensions.four,
                ),
                title: Text(
                  'Invite them to join your circle',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: Text(
                  ready
                      ? 'A short code will be ready to share by SMS or WhatsApp after setup.'
                      : 'Add their name and phone number to create an invite code.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
                ),
                value: ready && vm.inviteEmergencyContact.value,
                activeTrackColor: context.ink.withValues(alpha: 0.26),
                activeThumbColor: context.ink,
                onChanged: ready
                    ? (value) => vm.inviteEmergencyContact.value = value
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}
