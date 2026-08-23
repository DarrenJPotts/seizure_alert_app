import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';

class SosContactsSummary extends StatelessWidget {
  const SosContactsSummary({super.key, required this.contacts});

  final List<ContactDto> contacts;

  int get pushCount => contacts.where((ContactDto c) => c.notifyViaPush).length;

  int get smsCount => contacts.where((ContactDto c) => c.notifyViaSms).length;

  List<ContactDto> get visible => contacts.take(3).toList();

  int get overflow => contacts.length - visible.length;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return Text(
        'You have no contacts to notify yet.',
        style: context.theme.textTheme.bodySmall?.copyWith(color: Colors.black45),
      );
    }

    return Row(
      mainAxisSize: .min,
      children: [
        SizedBox(
          width: 34.0 + (visible.length - 1) * 24 + (overflow > 0 ? 24 : 0),
          height: 34,
          child: Stack(
            children: [
              for (int i = 0; i < visible.length; i++)
                Positioned(
                  left: i * 24.0,
                  child: _Avatar(contact: visible[i]),
                ),
              if (overflow > 0) Positioned(left: visible.length * 24.0, child: _Avatar.overflow(overflow)),
            ],
          ),
        ),
        SizedBox(width: Dimensions.twelve),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${contacts.length} contact${contacts.length == 1 ? '' : 's'} will be notified',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '$pushCount by push · $smsCount by SMS · location included',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
            ),
          ],
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.contact}) : overflowCount = null;

  const _Avatar.overflow(this.overflowCount) : contact = null;

  final ContactDto? contact;
  final int? overflowCount;

  @override
  Widget build(BuildContext context) {
    final bool muted = contact != null && !contact!.notifyViaPush;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: muted ? Colors.black.withValues(alpha: 0.08) : Colors.black,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          contact != null ? _initials(contact!.name) : '+$overflowCount',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: muted ? Colors.black54 : Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String _initials(String value) {
    final List<String> parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
