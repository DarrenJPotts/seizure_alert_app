import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.design.cardPadding),
      decoration: BoxDecoration(
        color: context.cardSurface,
        border: context.designBorder,
        boxShadow: context.designShadows,
        borderRadius: BorderRadius.circular(context.design.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Dimensions.eight,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.ink,
              height: 1,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
          ),
        ],
      ),
    );
  }
}
