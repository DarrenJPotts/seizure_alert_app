library;

import 'package:phone_numbers_parser/phone_numbers_parser.dart' as parser;

class PhoneNumber {
  const PhoneNumber._();

  /// Dial code assumed for numbers written in local form (e.g. "082 123 4567").
  ///
  /// This app currently ships to a single region. If that changes, this needs
  /// to become a per-user setting captured at sign-up, because a local-form
  /// number is genuinely ambiguous without it.
  static const String defaultDialCode = '27';

static String? normalize(String? raw) {
    if (raw == null) return null;

    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

final bool isInternational =
        trimmed.startsWith('+') || trimmed.startsWith('00');

    final String digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;

    String national;
    if (isInternational) {

national = trimmed.startsWith('00') ? digits.substring(2) : digits;
    } else if (digits.startsWith('0')) {

      national = '$defaultDialCode${digits.replaceFirst(RegExp(r'^0+'), '')}';
    } else if (digits.startsWith(defaultDialCode)) {
      national = digits;
    } else {
      national = '$defaultDialCode$digits';
    }

if (national.length < 8) return null;

    return '+$national';
  }

static bool isValid(String? raw) {
    if (raw == null || raw.trim().isEmpty) return false;
    try {
      final parser.PhoneNumber parsed = parser.PhoneNumber.parse(
        raw.trim(),
        callerCountry: parser.IsoCode.ZA,
      );
      return parsed.isoCode == parser.IsoCode.ZA && parsed.isValid();
    } catch (_) {
      return false;
    }
  }

  static String? validationError(String? raw, {bool required = false}) {
    if (raw == null || raw.trim().isEmpty) {
      return required ? 'Phone number is required' : null;
    }
    return isValid(raw) ? null : 'Enter a valid South African phone number';
  }

static bool matches(String? a, String? b) {
    final String? na = normalize(a);
    final String? nb = normalize(b);
    return na != null && na == nb;
  }
}
