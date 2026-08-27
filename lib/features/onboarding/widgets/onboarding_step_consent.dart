import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/constants/privacy_notice.dart';
import 'package:seizure_app/core/widgets/privacy_notice_sheet.dart';
import 'package:seizure_app/features/onboarding/view_models/onboarding_view_model.dart';

class OnboardingStepConsent extends StatelessWidget {
  const OnboardingStepConsent({super.key, required this.vm});

  final OnboardingViewModel vm;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      Dimensions.twentyFour,
      Dimensions.thirtyTwo,
      Dimensions.twentyFour,
      Dimensions.twentyFour,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Before you continue',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: Dimensions.twelve),
        Text(
          'Seizure Alert stores health information about you and shares it with '
          'the emergency contacts you choose. South African law requires your '
          'explicit agreement first.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.55, color: Colors.black54),
        ),
        SizedBox(height: Dimensions.twentyFour),
        const _WhatThisMeans(),
        SizedBox(height: Dimensions.twentyFour),
        Obx(
          () => _ConsentCheckbox(
            value: vm.privacyConsentGiven.value,
            onChanged: vm.setPrivacyConsent,
          ),
        ),
        SizedBox(height: Dimensions.twelve),
        TextButton(
          onPressed: () => PrivacyNoticeSheet.show(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Read how your information is used'),
        ),
      ],
    ),
  );
}

class _WhatThisMeans extends StatelessWidget {
  const _WhatThisMeans();

  static const List<({IconData icon, String text})> _points = <({IconData icon, String text})>[
    (icon: Icons.medical_information_outlined, text: 'Your seizure log and medical details are stored for you.'),
    (
      icon: Icons.group_outlined,
      text: 'Only the contacts you add can see them, and only when you send an alert.',
    ),
    (icon: Icons.location_on_outlined, text: 'Your location is captured when you alert — never continuously.'),
    (icon: Icons.delete_outline, text: 'You can delete your account and everything in it at any time.'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(Dimensions.eighteen),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < _points.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: Dimensions.fourteen),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(_points[i].icon, size: 20, color: Colors.black),
              SizedBox(width: Dimensions.fourteen),
              Expanded(
                child: Text(
                  _points[i].text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _ConsentCheckbox extends StatelessWidget {
  const _ConsentCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: value,
    label: PrivacyNotice.consentSummary,
    child: ExcludeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Dimensions.four),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: value ? Colors.black : Colors.white,
                  border: value ? null : Border.all(color: Colors.black.withValues(alpha: 0.3), width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: value ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
              ),
              SizedBox(width: Dimensions.fourteen),
              Expanded(
                child: Text(
                  PrivacyNotice.consentSummary,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
