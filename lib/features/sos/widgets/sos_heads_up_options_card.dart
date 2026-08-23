import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/heads_up/heads_up/heads_up_bottom_sheet_widget.dart';
import 'package:seizure_app/features/heads_up/view_models/heads_up_view_model.dart';

/// Bordered card on the SOS idle screen offering the lower-stakes Heads Up
/// route alongside SOS. Tapping a duration pre-selects it and opens the
/// Heads Up sheet to confirm and send.
class SosHeadsUpOptionsCard extends StatelessWidget {
  const SosHeadsUpOptionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Dimensions.sixteen),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_outlined, size: 20, color: Colors.black54),
              SizedBox(width: Dimensions.twelve),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Heads Up', style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      'Feeling off but not in danger yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.twelve),
          Row(
            spacing: Dimensions.eight,
            children: HeadsUpViewModel.windowOptions.map((int minutes) {
              final String label =
                  minutes == 60 ? '1 hr' : minutes == 120 ? '2 hrs' : '30 min';
              return Expanded(
                child: _DurationOption(
                  label: label,
                  onTap: () {
                    HeadsUpViewModel.instance().selectedMinutes.value = minutes;
                    HeadsUpBottomSheet.show();
                  },
                ),
              );
            }).toList(),
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
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
