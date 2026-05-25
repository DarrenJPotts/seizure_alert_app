import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key});

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
                Text('Last alert sent', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45)),
                Text('Today, 08:14 AM', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: Text('View log')),
        ],
      ),
    );
  }
}