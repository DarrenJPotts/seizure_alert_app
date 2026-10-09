import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';

class SosContactsSummary extends StatelessWidget {
  const SosContactsSummary({super.key, required this.contacts, this.onAddContact});

  final List<ContactDto> contacts;
  final VoidCallback? onAddContact;

  List<ContactDto> get recipients => contacts.where((ContactDto c) => c.isPushReady).toList();

  List<ContactDto> get visible => recipients.take(3).toList();

  int get overflow => recipients.length - visible.length;

  @override
  Widget build(BuildContext context) {
    if (recipients.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            contacts.isEmpty
                ? 'No emergency contacts are set up.'
                : 'No linked contacts are ready for app alerts. Invite a contact or enable push alerts.',
            textAlign: TextAlign.center,
            style: context.theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
          if (onAddContact != null)
            TextButton.icon(
              onPressed: onAddContact,
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: Text(contacts.isEmpty ? 'Add emergency contact' : 'Review My Circle'),
              style: TextButton.styleFrom(foregroundColor: Colors.black),
            ),
        ],
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
              '${recipients.length} contact${recipients.length == 1 ? '' : 's'} set to receive alerts',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Push notifications only',
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
    final bool muted = contact != null && !contact!.isPushReady;
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
