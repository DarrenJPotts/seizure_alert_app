import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool tappable;
  final VoidCallback? onTap;
  final Color? valueColor;

  const ProfileItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.tappable = false,
    this.onTap,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Dimensions.sixteen, vertical: Dimensions.twelve),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black45),
            SizedBox(width: Dimensions.twelve),
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: context.theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: context.theme.textTheme.bodySmall?.copyWith(color: valueColor ?? Colors.black45),
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (tappable) ...[
              SizedBox(width: Dimensions.eight),
              Icon(Icons.chevron_right, size: 16, color: Colors.black26),
            ],
          ],
        ),
      ),
    );
  }
}
