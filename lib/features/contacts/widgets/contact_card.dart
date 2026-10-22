import 'package:seizure_app/core/themes/app_palette.dart';
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
        padding: const EdgeInsets.only(right: Dimensions.twentyFour),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(context.design.cardRadius),
        ),
        child: Icon(Icons.delete_outline, color: Colors.red.shade400),
      ),
      confirmDismiss: (_) async => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: InkWell(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: context.ink,
                child: Text(
                  contact.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: context.paper,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.twelve),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Dimensions.four,
                  children: [
                    Text(
                      contact.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (contact.status == ContactStatus.pending ||
                        contact.inviteStatus == 'pending' ||
                        contact.inviteStatus == 'declined' ||
                        contact.linkedUid?.isNotEmpty == true)
                      _InviteStatusBadge(contact: contact),
                    Text(
                      _subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.secondaryInk,
                      ),
                    ),
                    if (contact.linkedUid?.isNotEmpty != true)
                      Wrap(
                        spacing: Dimensions.four,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (contact.linkedUid == null ||
                              contact.linkedUid!.isEmpty)
                            Tooltip(
                              message: _inviteTooltip,
                              child: TextButton.icon(
                                onPressed: isInviting ? null : onInvite,
                                icon: isInviting
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: context.ink,
                                          strokeWidth: 1.5,
                                        ),
                                      )
                                    : Icon(_inviteIcon, size: 16),
                                label: Text(
                                  isInviting ? 'Loading…' : _inviteActionLabel,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: Dimensions.eight),
              Padding(
                padding: const EdgeInsets.only(top: Dimensions.four),
                child: _NotifyIcons(contact: contact),
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
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.eight,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: context.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: context.secondaryInk),
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
            padding: const EdgeInsets.only(left: Dimensions.four),
            child: Icon(
              Icons.notifications_outlined,
              size: 16,
              color: context.ink.withValues(alpha: 0.38),
            ),
          ),
        ),
    ],
  );
}
