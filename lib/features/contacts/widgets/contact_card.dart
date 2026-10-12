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
    this.isInviting = false,
  });

  final ContactDto contact;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onInvite;
  final bool isInviting;

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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: Dimensions.twelve),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Dimensions.four,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            contact.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (contact.status == ContactStatus.pending ||
                            contact.inviteStatus != null ||
                            contact.linkedUid != null) ...[
                          SizedBox(width: Dimensions.eight),
                          _InviteStatusBadge(contact: contact),
                        ],
                      ],
                    ),
                    Text(
                      _subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black45),
                    ),
                  ],
                ),
              ),
              _NotifyIcons(contact: contact),
              SizedBox(width: Dimensions.four),
              if (contact.linkedUid == null || contact.linkedUid!.isEmpty)
                Tooltip(
                  message: _inviteTooltip,
                  child: TextButton.icon(
                    onPressed: isInviting ? null : onInvite,
                    icon: isInviting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 1.5,
                            ),
                          )
                        : Icon(_inviteIcon, size: 16),
                    label: Text(isInviting ? 'Loading…' : _inviteActionLabel),
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

  bool get _inviteExpired =>
      contact.inviteStatus == 'pending' &&
      contact.inviteExpiresAt != null &&
      contact.inviteExpiresAt!.isBefore(DateTime.now());

  String get _inviteActionLabel {
    if (_inviteExpired) return 'New code';
    if (contact.inviteStatus == 'pending') return 'View code';
    if (contact.inviteStatus == 'declined') return 'Invite again';
    return 'Invite';
  }

  String get _inviteTooltip {
    if (_inviteExpired) return 'Create a new invite code';
    if (contact.inviteStatus == 'pending') {
      return 'View or resend invite code';
    }
    return 'Create app invite';
  }

  IconData get _inviteIcon => contact.inviteStatus == 'pending'
      ? Icons.key_outlined
      : Icons.send_outlined;

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Remove contact?'),
      content: Text('${contact.name} will be removed from your circle.'),
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

class _InviteStatusBadge extends StatelessWidget {
  const _InviteStatusBadge({required this.contact});

  final ContactDto contact;

  @override
  Widget build(BuildContext context) {
    final String label;
    if (contact.linkedUid?.isNotEmpty == true) {
      label = switch (contact.lastTestStatus) {
        ContactAlertTestStatus.sent => 'Test successful',
        ContactAlertTestStatus.deviceOffline => 'Device offline',
        ContactAlertTestStatus.failed => 'Test failed',
        null => 'Connected',
      };
    } else if (contact.inviteStatus == 'pending' &&
        contact.inviteExpiresAt != null &&
        contact.inviteExpiresAt!.isBefore(DateTime.now())) {
      label = 'Expired';
    } else if (contact.inviteStatus == 'pending') {
      label = 'Awaiting response';
    } else if (contact.inviteStatus == 'declined') {
      label = 'Declined';
    } else if (contact.status == ContactStatus.pending) {
      label = 'Pending';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.eight, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: Colors.black54),
      ),
    );
  }
}

class _NotifyIcons extends StatelessWidget {
  const _NotifyIcons({required this.contact});

  final ContactDto contact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (contact.notifyViaPush)
        Tooltip(
          message: 'Push alerts on',
          child: Padding(
            padding: EdgeInsets.only(left: Dimensions.four),
            child: Icon(
              Icons.notifications_outlined,
              size: 16,
              color: Colors.black38,
            ),
          ),
        ),
    ],
  );
}
