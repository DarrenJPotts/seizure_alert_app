import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/helpers/phone_number.dart';
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

  // wa.me wants a full international number as bare digits, no plus. The old
  // implementation only stripped punctuation, so a locally-written number
  // like "082 123 4567" produced a wa.me link to a nonexistent subscriber.
  static String? _waMeDigits(String phone) =>
      PhoneNumber.normalize(phone)?.substring(1);

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
    final digits = _waMeDigits(phone);

    if (digits == null) {
      await _fallbackCopy(sender);
      return;
    }

    final uri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '/$digits',
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
      margin: EdgeInsets.all(Dimensions.sixteen),
      borderRadius: Dimensions.eight,
      duration: const Duration(seconds: 3),
    );
  }
}
