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
      padding: EdgeInsets.all(Dimensions.sixteen),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.06),
            ),
            child: Icon(icon, size: 20, color: Colors.black54),
          ),
          SizedBox(width: Dimensions.twelve),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  description,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
          SizedBox(width: Dimensions.twelve),
          if (granted)
            const Icon(Icons.check_circle, size: 20, color: Colors.black54)
          else
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black26),
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.twelve, vertical: Dimensions.eight),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
