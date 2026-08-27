const test = require("node:test");
const assert = require("node:assert/strict");

const { normalizePhone, DEFAULT_DIAL_CODE } = require("../phone");

/**
 * This must stay behaviourally identical to PhoneNumber.normalize in
 * lib/core/helpers/phone_number.dart. The client writes phoneNormalized and
 * the functions query on it, so any divergence means a contact is written
 * under one key and looked up under another — and receives no alerts, with
 * nothing in either UI to say so.
 *
 * The cases below are deliberately the same ones as
 * test/core/helpers/phone_number_test.dart. Change one, change both.
 */

test("collapses every local and international form of one number", () => {
  const expected = "+27821234567";
  const inputs = [
    "082 123 4567",
    "0821234567",
    "(082) 123-4567",
    "+27821234567",
    "+27 82 123 4567",
    "0027821234567",
    "27821234567",
    "821234567",
    "  082 123 4567  ",
  ];

  for (const input of inputs) {
    assert.equal(normalizePhone(input), expected, `input: ${input}`);
  }
});

test("keeps a foreign dial code rather than forcing the default", () => {
  assert.equal(normalizePhone("+44 7700 900123"), "+447700900123");
  assert.equal(normalizePhone("00447700900123"), "+447700900123");
});

test("returns null for values that are not usable numbers", () => {
  for (const input of [null, undefined, "", "   ", "abc", "123", 42, {}]) {
    assert.equal(normalizePhone(input), null, `input: ${JSON.stringify(input)}`);
  }
});

test("is idempotent — normalising twice changes nothing", () => {
  const once = normalizePhone("082 123 4567");
  assert.equal(normalizePhone(once), once);
});

test("distinct subscribers do not collide", () => {
  assert.notEqual(
    normalizePhone("082 123 4567"),
    normalizePhone("082 123 4568")
  );
});

test("strips punctuation without altering the digits", () => {
  assert.equal(normalizePhone("+27-82-123-4567"), "+27821234567");
  assert.equal(normalizePhone("+27.82.123.4567"), "+27821234567");
  assert.equal(normalizePhone("+27 (82) 123 4567"), "+27821234567");
});

test("treats a leading 00 as the international prefix, not a trunk zero", () => {
  // "00" is the international access code, so "00821234567" is +82 (South
  // Korea) and NOT the local South African "0821234567". This is a real trap:
  // the two strings differ by one character and resolve to different
  // countries. Both implementations must agree, or a contact saved on one side
  // is looked up under a different key on the other.
  assert.equal(normalizePhone("00821234567"), "+821234567");
  assert.equal(normalizePhone("0821234567"), "+27821234567");
  assert.notEqual(
    normalizePhone("00821234567"),
    normalizePhone("0821234567")
  );
});

test("exposes the dial code it assumes for local-form numbers", () => {
  // Local-form numbers are ambiguous without this, so it is part of the
  // contract rather than an implementation detail. Changing it silently
  // re-points every un-backfilled local number at a different country.
  assert.equal(DEFAULT_DIAL_CODE, "27");
});

test("rejects a number too short to be dialable", () => {
  assert.equal(normalizePhone("+27 12"), null);
  assert.equal(normalizePhone("0 1 2"), null);
});
