import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/heads_up/heads_up/heads_up_bottom_sheet_widget.dart';
import 'package:seizure_app/features/heads_up/view_models/heads_up_view_model.dart';

class SosHeadsUpOptionsCard extends StatelessWidget {
  const SosHeadsUpOptionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.sixteen),
      decoration: BoxDecoration(
        border: context.designBorder,
        boxShadow: context.designShadows,
        borderRadius: BorderRadius.circular(context.design.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_outlined,
                size: 20,
                color: context.secondaryInk,
              ),
              const SizedBox(width: Dimensions.twelve),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heads Up',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Feeling off but not in danger yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.secondaryInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.twelve),
          Wrap(
            spacing: Dimensions.eight,
            runSpacing: Dimensions.eight,
            children: HeadsUpViewModel.windowOptions.map((int minutes) {
              final String label = minutes == 60
                  ? '1 hr'
                  : minutes == 120
                  ? '2 hrs'
                  : '30 min';
              return _DurationOption(
                label: label,
                onTap: () {
                  HeadsUpViewModel.instance().selectedMinutes.value = minutes;
                  HeadsUpBottomSheet.show();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: Dimensions.eight),
          TextButton.icon(
            onPressed: () => HeadsUpBottomSheet.show(customDuration: true),
            icon: const Icon(Icons.schedule_outlined),
            label: const Text('Custom duration'),
          ),
        ],
      ),
    );
  }
}

class _DurationOption extends StatelessWidget {
  const _DurationOption({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: Dimensions.fortyEight),
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.sixteen,
          vertical: Dimensions.twelve,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: context.ink.withValues(alpha: 0.26)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
