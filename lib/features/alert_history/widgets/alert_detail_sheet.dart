import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/widgets/alert_map_widget.dart';
import 'package:seizure_app/core/widgets/alert_responses_widget.dart';

class AlertDetailSheet extends StatelessWidget {
  const AlertDetailSheet({super.key, required this.alert});

  final AlertDto alert;

  static void show(AlertDto alert) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => AlertDetailSheet(alert: alert),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = alert.latitude != null && alert.longitude != null;

    return SingleChildScrollView(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: EdgeInsets.all(Dimensions.twentyFour),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: EdgeInsets.only(bottom: Dimensions.twentyFour),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(Dimensions.circular),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                  child: Icon(alertIconForType(alert.type),
                      size: 22, color: Colors.black54),
                ),
                SizedBox(width: Dimensions.twelve),
                Expanded(
                  child: Text(alertLabelForType(alert.type),
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              ],
            ),
            SizedBox(height: Dimensions.twentyFour),
            _DetailRow(label: 'Sent', value: formatAlertDate(alert.createdAt)),
            if (alert.resolvedAt != null) ...[
              SizedBox(height: Dimensions.twelve),
              _DetailRow(
                label: alert.status == AlertStatus.cancelled
                    ? 'Cancelled'
                    : 'Resolved',
                value: formatAlertDate(alert.resolvedAt!),
              ),
            ],
            if (alert.message != null && alert.message!.isNotEmpty) ...[
              SizedBox(height: Dimensions.twelve),
              _DetailRow(label: 'Note', value: alert.message!),
            ],
            if (alert.locationLabel != null &&
                alert.locationLabel!.isNotEmpty) ...[
              SizedBox(height: Dimensions.twelve),
              _DetailRow(label: 'Location', value: alert.locationLabel!),
            ],
            SizedBox(height: Dimensions.twentyFour),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: hasLocation
                  ? AlertMapWidget(
                      latitude: alert.latitude!,
                      longitude: alert.longitude!,
                    )
                  : const AlertMapPlaceholder(),
            ),
            SizedBox(height: Dimensions.twentyFour),
            AlertResponsesWidget(alertId: alert.id),
            SizedBox(height: Dimensions.twentyFour),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.black45),
          ),
        ),
        Expanded(
          child:
              Text(value, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

IconData alertIconForType(AlertType type) {
  switch (type) {
    case AlertType.sos:
      return Icons.warning_amber_rounded;
    case AlertType.headsUp:
      return Icons.timer_outlined;
    case AlertType.headsUpExpired:
      return Icons.timer_off_outlined;
  }
}

String alertLabelForType(AlertType type) {
  switch (type) {
    case AlertType.sos:
      return 'SOS';
    case AlertType.headsUp:
      return 'Heads Up';
    case AlertType.headsUpExpired:
      return 'Heads Up Expired';
  }
}

String alertLabelForStatus(AlertStatus status) {
  switch (status) {
    case AlertStatus.sent:
      return 'Active';
    case AlertStatus.resolved:
      return 'Resolved';
    case AlertStatus.cancelled:
      return 'Cancelled';
  }
}

String formatAlertDate(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(date).inDays;
  if (diff == 0) return 'Today, ${_formatTime(dt)}';
  if (diff == 1) return 'Yesterday, ${_formatTime(dt)}';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${_formatTime(dt)}';
}

String _formatTime(DateTime dt) {
  final raw = dt.hour % 12;
  final h = raw == 0 ? 12 : raw;
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
}
