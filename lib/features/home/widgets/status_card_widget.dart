import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/widgets/live_indicator.dart';

class StatusCardWidget extends StatelessWidget {
  const StatusCardWidget({super.key, required this.contactCount});

  /// Live contact count streamed from Firestore.
  final int contactCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(Dimensions.twenty),
    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Dimensions.eight,
            children: [
              Text(
                'STATUS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white54, letterSpacing: 1.2),
              ),
              Text(
                'Monitoring Active',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Text(_contactsLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60)),
            ],
          ),
        ),
        const LiveIndicator(size: 14, color: Colors.white),
      ],
    ),
  );

  String get _contactsLabel {
    if (contactCount == 0) return 'No contacts in your circle yet';
    if (contactCount == 1) return '1 contact in your circle';
    return '$contactCount contacts in your circle';
  }
}
