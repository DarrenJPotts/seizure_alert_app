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
      padding: EdgeInsets.all(Dimensions.sixteen),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.history, size: 20, color: Colors.black45),
          SizedBox(width: Dimensions.twelve),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  'Last alert sent',
                  style: context.theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black45,
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
