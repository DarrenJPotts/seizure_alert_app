import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';

class ContactCard extends StatelessWidget {
  const ContactCard({
    super.key,
    required this.contact,
    required this.onTap,
    required this.onDelete,
    required this.onInvite,
  });

  final ContactDto contact;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(contact.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: Dimensions.twentyFour),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: Colors.red.shade400),
      ),
      confirmDismiss: (_) async => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: InkWell(
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
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.black,
                child: Text(
                  contact.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: Dimensions.twelve),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(contact.name,
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      _subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black45),
                    ),
                  ],
                ),
              ),
              _NotifyIcons(contact: contact),
              SizedBox(width: Dimensions.four),
              Tooltip(
                message: 'Send app invite',
                child: GestureDetector(
                  onTap: onInvite,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.send_outlined,
                        size: 16, color: Colors.black38),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    final relation = contact.relation;
    if (relation != null && relation.isNotEmpty) {
      return '$relation · ${contact.phone}';
    }
    return contact.phone;
  }

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove contact?'),
          content:
              Text('${contact.name} will be removed from your circle.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
}

class _NotifyIcons extends StatelessWidget {
  const _NotifyIcons({required this.contact});

  final ContactDto contact;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (contact.notifyViaSms)
            Tooltip(
              message: 'SMS alerts on',
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.sms_outlined,
                    size: 16, color: Colors.black38),
              ),
            ),
          if (contact.notifyViaPush)
            Tooltip(
              message: 'Push alerts on',
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.notifications_outlined,
                    size: 16, color: Colors.black38),
              ),
            ),
        ],
      );
}
