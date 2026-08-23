import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/services/invite_service.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';

class InvitePickerSheet extends StatelessWidget {
  const InvitePickerSheet({
    super.key,
    required this.phone,
    required this.contactName,
  });

  final String phone;
  final String contactName;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Text(
            'Invite $contactName',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: Dimensions.four),
          Text(
            'Send them a link to download SeizureAlert.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black45),
          ),
          SizedBox(height: Dimensions.twentyFour),

          // ── SMS ───────────────────────────────────────────────────────
          _ChannelRow(
            icon: Icons.sms_outlined,
            label: 'Via SMS',
            onTap: () {
              Get.back();
              InviteService.sendSmsInvite(phone: phone);
            },
          ),
          SizedBox(height: Dimensions.twelve),

          // ── WhatsApp ──────────────────────────────────────────────────
          _ChannelRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Via WhatsApp',
            onTap: () {
              Get.back();
              InviteService.sendWhatsAppInvite(phone: phone);
            },
          ),
          SizedBox(height: Dimensions.sixteen),

          // ── Skip ──────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Get.back(),
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              child: const Text('Skip'),
            ),
          ),
          SizedBox(height: Dimensions.eight),
        ],
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
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
              child: Icon(icon, size: 20, color: Colors.black54),
            ),
            SizedBox(width: Dimensions.twelve),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
