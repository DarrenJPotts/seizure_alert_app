import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

/// Black status-board header shown at the top of the active-SOS screen.
/// Shows a live "SOS ACTIVE" indicator, elapsed time, a segmented
/// seen-indicator, and an "X of Y contacts have seen this" caption.
class SosStatusBoardHeader extends StatelessWidget {
  const SosStatusBoardHeader({
    super.key,
    required this.elapsedLabel,
    required this.seenCount,
    required this.totalCount,
    required this.onCancel,
  });

  final String elapsedLabel;
  final int seenCount;
  final int totalCount;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: EdgeInsets.fromLTRB(
        Dimensions.twentyFour,
        Dimensions.twentyFour,
        Dimensions.twentyFour,
        Dimensions.twenty,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.greenAccent),
              ),
              SizedBox(width: Dimensions.eight),
              Expanded(
                child: Text(
                  'SOS ACTIVE',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 3),
                ),
              ),
              GestureDetector(
                onTap: onCancel,
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.twenty),
          Text(
            elapsedLabel,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              height: 1,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(height: Dimensions.twenty),
          Row(
            children: List.generate(totalCount == 0 ? 1 : totalCount, (i) {
              final filled = i < seenCount;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i == (totalCount == 0 ? 0 : totalCount - 1) ? 0 : Dimensions.four),
                  height: 4,
                  decoration: BoxDecoration(
                    color: filled ? Colors.white : Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(Dimensions.circular),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: Dimensions.twelve),
          Text(
            totalCount == 0 ? 'No contacts to notify' : '$seenCount of $totalCount contacts have seen this',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
