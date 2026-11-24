import 'package:flutter/services.dart';
import 'package:seizure_app/core/helpers/phone_number.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seizure_app/core/helpers/app_snackbar.dart';

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
    } catch (_) {}

    await Clipboard.setData(ClipboardData(text: normalized));
    _notify('Could not open dialler', '$normalized copied to clipboard.');
  }

  /// Emergency number dialled from the caregiver alert screens. 112 works
  /// from any mobile in South Africa and most other countries.
  static const String emergencyNumber = '112';

  /// Dials [emergencyNumber] directly. It is too short to pass
  /// [PhoneNumber.normalize], which is for saved contact numbers.
  static Future<void> callEmergency() async {
    final Uri uri = Uri(scheme: 'tel', path: emergencyNumber);
    try {
      if (await canLaunchUrl(uri) && await launchUrl(uri)) return;
    } catch (_) {}
    await Clipboard.setData(const ClipboardData(text: emergencyNumber));
    _notify(
      'Could not open dialler',
      'Dial $emergencyNumber yourself. It has been copied to the clipboard.',
    );
  }

  static void _notify(String title, String message) =>
      showAppSnackbar(title, message);
}
