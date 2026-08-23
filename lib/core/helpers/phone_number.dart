/// Canonical phone-number handling.
///
/// Every cross-user link in this app — notifying a contact circle, resolving
/// "people I watch", authorising an alert detail read, matching a circle
/// invite — is a phone-number lookup. Those lookups are exact-match queries,
/// so a contact saved as "082 123 4567" against an account registered as
/// "+27 82 123 4567" would silently never match, and the person would receive
/// no alerts at all.
///
/// To avoid that, every document that stores a phone number also stores a
/// normalised E.164 copy under `phoneNormalized`, and all matching is done on
/// that field. The raw `phone` value is kept untouched for display, so the
/// user still sees the number the way they typed it.
///
/// The equivalent JavaScript implementation lives in `functions/phone.js` —
/// the two must stay in sync.
library;

class PhoneNumber {
  const PhoneNumber._();

  /// Dial code assumed for numbers written in local form (e.g. "082 123 4567").
  ///
  /// This app currently ships to a single region. If that changes, this needs
  /// to become a per-user setting captured at sign-up, because a local-form
  /// number is genuinely ambiguous without it.
  static const String defaultDialCode = '27';

  /// Converts [raw] into E.164 form (`+27821234567`).
  ///
  /// Returns `null` when [raw] holds too few digits to be a usable number,
  /// so callers can distinguish "no number" from "some number".
  static String? normalize(String? raw) {
    if (raw == null) return null;

    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // An explicit international prefix always wins over the default dial code.
    final bool isInternational =
        trimmed.startsWith('+') || trimmed.startsWith('00');

    final String digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;

    String national;
    if (isInternational) {
      // "0027..." and "+27..." both reduce to the same digits once the
      // leading zeros of the 00-prefix are dropped.
      national = trimmed.startsWith('00') ? digits.substring(2) : digits;
    } else if (digits.startsWith('0')) {
      // Local trunk form: drop the trunk zero, prepend the default dial code.
      national = '$defaultDialCode${digits.replaceFirst(RegExp(r'^0+'), '')}';
    } else if (digits.startsWith(defaultDialCode)) {
      // Already carries the dial code, just without the plus.
      national = digits;
    } else {
      national = '$defaultDialCode$digits';
    }

    // Shortest realistic E.164 number is 8 digits including the dial code.
    if (national.length < 8) return null;

    return '+$national';
  }

  /// Whether [raw] can be normalised into a usable number.
  static bool isValid(String? raw) => normalize(raw) != null;

  /// True when both values refer to the same subscriber.
  static bool matches(String? a, String? b) {
    final String? na = normalize(a);
    final String? nb = normalize(b);
    return na != null && na == nb;
  }
}
