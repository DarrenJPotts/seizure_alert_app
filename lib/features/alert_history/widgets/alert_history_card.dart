import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/features/alert_history/widgets/alert_detail_sheet.dart';

class AlertHistoryCard extends StatelessWidget {
  const AlertHistoryCard({super.key, required this.alert, required this.onTap});

  final AlertDto alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.design.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.sixteen),
        decoration: BoxDecoration(
          color: context.cardSurface,
          border: context.designBorder,
          boxShadow: context.designShadows,
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
              child: Icon(
                alertIconForType(alert.type),
                size: 20,
                color: context.secondaryInk,
              ),
            ),
            const SizedBox(width: Dimensions.twelve),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Dimensions.four,
                children: [
                  Text(
                    alert.ownerName == null
                        ? alertLabelForType(alert.type)
                        : '${alert.ownerName} · ${alertLabelForType(alert.type)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    formatAlertDate(alert.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.secondaryInk,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.ink.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      alertLabelForStatus(alert.status),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.secondaryInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Dimensions.eight),
            Icon(
              Icons.chevron_right,
              color: context.ink.withValues(alpha: 0.26),
            ),
          ],
        ),
      ),
    );
  }
}
