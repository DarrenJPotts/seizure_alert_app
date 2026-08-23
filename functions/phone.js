/**
 * Canonical phone-number handling.
 *
 * Mirror of `lib/core/helpers/phone_number.dart` — the two implementations
 * must stay in sync, since the client writes `phoneNormalized` and these
 * functions query on it.
 */

// Dial code assumed for numbers written in local form (e.g. "082 123 4567").
const DEFAULT_DIAL_CODE = "27";

/**
 * Converts a raw phone string into E.164 form (`+27821234567`).
 * Returns null when there aren't enough digits to be a usable number.
 */
function normalizePhone(raw) {
  if (typeof raw !== "string") return null;

  const trimmed = raw.trim();
  if (!trimmed) return null;

  const isInternational = trimmed.startsWith("+") || trimmed.startsWith("00");

  const digits = trimmed.replace(/[^0-9]/g, "");
  if (!digits) return null;

  let national;
  if (isInternational) {
    national = trimmed.startsWith("00") ? digits.slice(2) : digits;
  } else if (digits.startsWith("0")) {
    national = DEFAULT_DIAL_CODE + digits.replace(/^0+/, "");
  } else if (digits.startsWith(DEFAULT_DIAL_CODE)) {
    national = digits;
  } else {
    national = DEFAULT_DIAL_CODE + digits;
  }

  if (national.length < 8) return null;

  return "+" + national;
}

module.exports = { normalizePhone, DEFAULT_DIAL_CODE };
