import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/constants/snackbar_margin.dart';
import 'package:seizure_app/core/helpers/phone_number.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteService {
  InviteService._();

  static const _appUrl = 'https://seizurealert.app';

  static String _buildMessage(String senderName, String code) =>
      '$senderName invited you to join their SeizureAlert circle. '
      'Sign in or create an account, open My Circle, and enter this one-time code: $code. '
      'It expires 24 hours after it was generated. Download the app: $_appUrl';

  static String _senderName() =>
      FirebaseAuth.instance.currentUser?.displayName?.trim() ?? 'Your contact';

  static String? _waMeDigits(String phone) =>
      PhoneNumber.normalize(phone)?.substring(1);

  static Future<void> sendSmsInvite({
    required String phone,
    required String code,
  }) async {
    final sender = _senderName();
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': _buildMessage(sender, code)},
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await _fallbackCopy(sender, code);
      }
    } catch (_) {
      await _fallbackCopy(sender, code);
    }
  }

  static Future<void> sendWhatsAppInvite({
    required String phone,
    required String code,
  }) async {
    final sender = _senderName();
    final digits = _waMeDigits(phone);

    if (digits == null) {
      await _fallbackCopy(sender, code);
      return;
    }

    final uri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '/$digits',
      queryParameters: {'text': _buildMessage(sender, code)},
    );

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await _fallbackCopy(sender, code);
    }
  }

  static Future<void> _fallbackCopy(String senderName, String code) async {
    await Clipboard.setData(
      ClipboardData(text: _buildMessage(senderName, code)),
    );
    Get.snackbar(
      '',
      '',
      titleText: const Text(
        'Could not open app',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      messageText: const Text(
        'Invite message copied to clipboard.',
        style: TextStyle(color: Colors.white),
      ),
      snackPosition: SnackPosition.BOTTOM,
      margin: snackbarMargin,
      backgroundColor: Colors.black,
      borderRadius: Dimensions.eight,
      duration: const Duration(seconds: 3),
    );
  }
}
