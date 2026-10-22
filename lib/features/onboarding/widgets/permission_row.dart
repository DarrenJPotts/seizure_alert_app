import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class PermissionRow extends StatelessWidget {
  const PermissionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.granted,
    required this.onTap,
    this.blocked = false,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool granted;

  final bool blocked;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.sixteen),
      decoration: BoxDecoration(
        border: context.designBorder,
        borderRadius: BorderRadius.circular(context.design.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.ink.withValues(alpha: 0.06),
            ),
            child: Icon(icon, size: 20, color: context.secondaryInk),
          ),
          const SizedBox(width: Dimensions.twelve),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
                ),
              ],
            ),
          ),
          const SizedBox(width: Dimensions.twelve),
          if (granted)
            Icon(Icons.check_circle, size: 20, color: context.secondaryInk)
          else
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: context.ink,
                side: BorderSide(color: context.ink.withValues(alpha: 0.26)),
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.twelve,
                  vertical: Dimensions.eight,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Text(
                blocked ? 'Open settings' : 'Enable',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
