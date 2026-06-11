import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteService {
  InviteService._();

  static const _appUrl = 'https://seizurealert.app';

  static String _buildMessage(String senderName) =>
      '$senderName added you as their emergency contact on SeizureAlert. '
      "If they send an SOS or Heads Up alert, you'll receive a notification. "
      'Download the app: $_appUrl';

  static String _senderName() =>
      FirebaseAuth.instance.currentUser?.displayName?.trim() ?? 'Your contact';

  // ─── Strip everything except digits and leading + ─────────────────────────
  static String _normalizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[\s\-\(\)]'), '').replaceFirst('+', '');

  // ─── Public entry point — shows the channel picker ────────────────────────

  static void showInvitePicker({
    required String phone,
    required String contactName,
  }) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _InvitePickerSheet(phone: phone, contactName: contactName),
    );
  }

  // ─── SMS ──────────────────────────────────────────────────────────────────

  static Future<void> sendSmsInvite({required String phone}) async {
    final sender = _senderName();
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': _buildMessage(sender)},
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await _fallbackCopy(sender);
      }
    } catch (_) {
      await _fallbackCopy(sender);
    }
  }

  // ─── WhatsApp ─────────────────────────────────────────────────────────────

  static Future<void> sendWhatsAppInvite({required String phone}) async {
    final sender = _senderName();
    final normalized = _normalizePhone(phone);
    final uri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '/$normalized',
      queryParameters: {'text': _buildMessage(sender)},
    );

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await _fallbackCopy(sender);
    }
  }

  // ─── Clipboard fallback ───────────────────────────────────────────────────

  static Future<void> _fallbackCopy(String senderName) async {
    await Clipboard.setData(ClipboardData(text: _buildMessage(senderName)));
    Get.snackbar(
      '',
      '',
      titleText: const Text(
        'Could not open app',
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      messageText: const Text(
        'Invite message copied to clipboard.',
        style: TextStyle(color: Colors.white),
      ),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }
}

// ─── Invite picker sheet ──────────────────────────────────────────────────────

class _InvitePickerSheet extends StatelessWidget {
  const _InvitePickerSheet({required this.phone, required this.contactName});

  final String phone;
  final String contactName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(Dimensions.twentyFour),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ────────────────────────────────────────────────────
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

          // ── Header ────────────────────────────────────────────────────
          Text('Invite $contactName',
              style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: Dimensions.four),
          Text(
            'Send them a link to download SeizureAlert.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.black45),
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
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
