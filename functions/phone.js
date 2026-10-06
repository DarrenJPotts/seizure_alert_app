

const DEFAULT_DIAL_CODE = "27";

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
