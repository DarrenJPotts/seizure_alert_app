import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/themes/app_palette.dart';
import '../models/medical_card_data.dart';

class MedicalCardPreview extends StatelessWidget {
  const MedicalCardPreview({super.key, required this.details});
  final Map<MedicalCardField, String> details;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(context.design.featureRadius),
        border: context.designBorder,
        boxShadow: context.designShadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: context.heroSurface,
            padding: const EdgeInsets.all(Dimensions.twentyFour),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      color: context.heroInk,
                    ),
                    const SizedBox(width: Dimensions.twelve),
                    Expanded(
                      child: Text(
                        'MEDICAL CARD',
                        style: text.labelLarge?.copyWith(
                          color: context.heroInk,
                        ),
                      ),
                    ),
                  ],
                ),
                if (details.containsKey(MedicalCardField.name)) ...[
                  const SizedBox(height: Dimensions.twenty),
                  Text(
                    details[MedicalCardField.name]!,
                    style: text.headlineMedium?.copyWith(
                      color: context.heroInk,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Dimensions.twentyFour),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in details.entries.where(
                  (entry) => entry.key != MedicalCardField.name,
                )) ...[
                  Text(
                    entry.key.label,
                    style: text.bodySmall?.copyWith(
                      color: context.secondaryInk,
                    ),
                  ),
                  const SizedBox(height: Dimensions.four),
                  Text(
                    entry.value,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Dimensions.twenty),
                ],
                if (details.isEmpty) ...[
                  Text(
                    'Choose details to include in your card.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: Dimensions.twenty),
                ],
                Divider(
                  color: context.ink.withValues(alpha: 0.12),
                  height: Dimensions.sixteen,
                ),
                const SizedBox(height: Dimensions.sixteen),
                Text(
                  'Self-reported information.\nNot clinically verified.',
                  style: text.bodySmall?.copyWith(color: context.secondaryInk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
