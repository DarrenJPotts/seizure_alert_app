import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/services/call_service.dart';

/// One row in the active-SOS status board's contact list.
/// Shows an initials avatar (filled once seen/responding), the contact's
/// name, their current status, and a call button.
class ContactStatusRow extends StatelessWidget {
  const ContactStatusRow({
    super.key,
    required this.name,
    required this.phone,
    required this.seen,
    required this.responding,
  });

  final String name;
  final String phone;
  final bool seen;
  final bool responding;

  @override
  Widget build(BuildContext context) {
    final active = seen || responding;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Dimensions.eight),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? Colors.black : Colors.black.withValues(alpha: 0.06),
              border: active ? null : Border.all(color: Colors.black12),
            ),
            child: Center(
              child: Text(
                _initials(name),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: active ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          SizedBox(width: Dimensions.twelve),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  responding
                      ? 'Responding'
                      : seen
                          ? 'Seen'
                          : 'Not seen yet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: responding ? Colors.black87 : Colors.black45,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => CallService.call(phone),
            icon: const Icon(Icons.call_outlined, color: Colors.black),
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
}
