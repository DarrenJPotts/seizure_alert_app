import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    required this.label,
    required this.hasAlert,
    required this.onViewLog,
  });

  final String label;

  final bool hasAlert;

  final VoidCallback onViewLog;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.sixteen),
      decoration: BoxDecoration(
        border: context.designBorder,
        boxShadow: context.designShadows,
        borderRadius: BorderRadius.circular(context.design.cardRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.history, size: 20, color: context.secondaryInk),
          const SizedBox(width: Dimensions.twelve),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  'Last alert sent',
                  style: context.theme.textTheme.bodySmall?.copyWith(
                    color: context.secondaryInk,
                  ),
                ),
                Text(label, style: context.theme.textTheme.bodyMedium),
              ],
            ),
          ),
          if (hasAlert)
            TextButton(onPressed: onViewLog, child: const Text('View log')),
        ],
      ),
    );
  }
}
