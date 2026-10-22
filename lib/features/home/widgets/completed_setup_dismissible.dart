import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/themes/app_palette.dart';

/// Only completed checks may be hidden; readiness problems remain visible.
class CompletedSetupDismissible extends StatelessWidget {
  const CompletedSetupDismissible({
    super.key,
    required this.enabled,
    required this.onDismissed,
    required this.child,
  });
  final bool enabled;
  final VoidCallback onDismissed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Dismissible(
      key: const ValueKey('completed-setup-check'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        HapticFeedback.selectionClick();
        onDismissed();
      },
      background: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.ink.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(Dimensions.twelve),
        ),
        child: Icon(Icons.visibility_off_outlined, color: context.secondaryInk),
      ),
      child: child,
    );
  }
}
