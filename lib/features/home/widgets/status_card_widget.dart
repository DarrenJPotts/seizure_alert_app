import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class StatusCardWidget extends StatelessWidget {
  const StatusCardWidget({super.key, required this.contactCount});

  /// Live contact count streamed from Firestore.
  final int contactCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(Dimensions.twenty),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Dimensions.eight,
            children: [
              Text(
                'STATUS',
                style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.2),
              ),
              Text(
                'Monitoring Active',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text(
                _contactsLabel,
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
        // Pulsing green indicator dot
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.greenAccent,
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String get _contactsLabel {
    if (contactCount == 0) return 'No contacts in your circle yet';
    if (contactCount == 1) return '1 contact in your circle';
    return '$contactCount contacts in your circle';
  }
}
