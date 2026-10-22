import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/services/call_service.dart';

class ContactStatusRow extends StatelessWidget {
  const ContactStatusRow({
    super.key,
    required this.name,
    required this.phone,
    required this.seen,
    required this.responding,
    this.deliveryStatus,
    this.escalationStage = 0,
  });

  final String name;
  final String phone;
  final bool seen;
  final bool responding;
  final String? deliveryStatus;
  final int escalationStage;

  @override
  Widget build(BuildContext context) {
    final active = seen || responding;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.eight),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? context.ink : context.ink.withValues(alpha: 0.06),
              border: active ? null : context.designBorder,
            ),
            child: Center(
              child: Text(
                _initials(name),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: active ? context.paper : context.secondaryInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.twelve),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  _statusLabel(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: responding
                        ? context.ink.withValues(alpha: 0.87)
                        : context.secondaryInk,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => CallService.call(phone),
            icon: Icon(Icons.call_outlined, color: context.ink),
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _statusLabel() {
    if (responding) return 'Responding';
    if (seen) return 'Seen';
    if (deliveryStatus == 'deviceOffline') return 'Device unavailable';
    if (deliveryStatus == 'failed') return 'Delivery failed';
    if (deliveryStatus == 'sent' && escalationStage > 0) {
      return 'Reminder sent';
    }
    if (deliveryStatus == 'sent') return 'Alert sent';
    return 'Sending';
  }
}
