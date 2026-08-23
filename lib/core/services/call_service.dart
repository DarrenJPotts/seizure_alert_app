import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/helpers/phone_number.dart';
import 'package:url_launcher/url_launcher.dart';

/// Places a phone call, or tells the user why it couldn't.
///
/// Every call site previously did `if (await canLaunchUrl(uri)) launchUrl(uri)`
/// and nothing else, so a device that refused the `tel:` scheme produced a
/// button that appeared to work and did nothing. During an emergency that is
/// the worst possible failure mode, so a refusal now falls back to putting the
/// number on the clipboard and saying so.
class CallService {
  CallService._();

  static Future<void> call(String? phone) async {
    final String? normalized = PhoneNumber.normalize(phone);
    if (normalized == null) {
      _notify('No number saved', 'This contact has no usable phone number.');
      return;
    }

    final Uri uri = Uri(scheme: 'tel', path: normalized);

    try {
      if (await canLaunchUrl(uri) && await launchUrl(uri)) return;
    } catch (_) {
      // Fall through to the clipboard fallback below.
    }

    await Clipboard.setData(ClipboardData(text: normalized));
    _notify('Could not open dialler', '$normalized copied to clipboard.');
  }

  static void _notify(String title, String message) {
    Get.snackbar(
      '',
      '',
      titleText: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      messageText: Text(message, style: const TextStyle(color: Colors.white)),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black,
      margin: EdgeInsets.all(Dimensions.sixteen),
      borderRadius: Dimensions.eight,
      duration: const Duration(seconds: 4),
    );
  }
}
