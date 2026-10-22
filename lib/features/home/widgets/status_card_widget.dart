import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/widgets/live_indicator.dart';

class StatusCardWidget extends StatelessWidget {
  const StatusCardWidget({super.key, required this.contactCount});

  final int contactCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Dimensions.twenty),
    decoration: BoxDecoration(
      color: context.heroSurface,
      borderRadius: BorderRadius.circular(context.design.featureRadius),
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.heroInk.withValues(alpha: 0.54),
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Monitoring Active',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.heroInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _contactsLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.heroInk.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        LiveIndicator(size: 14, color: context.heroInk),
      ],
    ),
  );

  String get _contactsLabel {
    if (contactCount == 0) return 'No contacts in your circle yet';
    if (contactCount == 1) return '1 contact in your circle';
    return '$contactCount contacts in your circle';
  }
}
