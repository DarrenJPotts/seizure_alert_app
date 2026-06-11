import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/features/alert_history/widgets/alert_detail_sheet.dart';

class AlertHistoryCard extends StatelessWidget {
  const AlertHistoryCard({
    super.key,
    required this.alert,
    required this.onTap,
  });

  final AlertDto alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
              child: Icon(
                alertIconForType(alert.type),
                size: 20,
                color: Colors.black54,
              ),
            ),
            SizedBox(width: Dimensions.twelve),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(alertLabelForType(alert.type),
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    formatAlertDate(alert.createdAt),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black45),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                alertLabelForStatus(alert.status),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.black54),
              ),
            ),
            SizedBox(width: Dimensions.eight),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
