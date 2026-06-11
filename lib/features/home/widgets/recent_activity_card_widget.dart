import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    required this.label,
    required this.hasAlert,
    required this.onViewLog,
  });

  /// Human-readable timestamp of the most recent alert, e.g. "Today, 8:14 AM".
  /// When [hasAlert] is false this shows a friendly empty-state message.
  final String label;

  /// Whether there is at least one historical alert to navigate to.
  final bool hasAlert;

  /// Callback invoked when the user taps "View log".
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
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.black45),
                ),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (hasAlert)
            TextButton(
              onPressed: onViewLog,
              child: const Text('View log'),
            ),
        ],
      ),
    );
  }
}
