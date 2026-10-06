import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class OnboardingField extends StatelessWidget {
  const OnboardingField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.errorText,
    this.helper,
    this.autofocus = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final String? errorText;
  final String? helper;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Dimensions.eight,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        TextField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          style: Theme.of(context).textTheme.bodyMedium,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            errorText: errorText,
            counterText: maxLength == null ? null : '',
          ),
        ),
      ],
    );
  }
}
