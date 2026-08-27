import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/helpers/phone_number.dart';

void main() {
  group('PhoneNumber.normalize', () {
    test('collapses every local and international form of one number', () {
      const String expected = '+27821234567';
      for (final String input in <String>[
        '082 123 4567',
        '0821234567',
        '(082) 123-4567',
        '+27821234567',
        '+27 82 123 4567',
        '0027821234567',
        '27821234567',
        '821234567',
        '  082 123 4567  ',
      ]) {
        expect(PhoneNumber.normalize(input), expected, reason: 'input: $input');
      }
    });

    test('keeps a foreign dial code rather than forcing the default', () {
      expect(PhoneNumber.normalize('+44 7700 900123'), '+447700900123');
      expect(PhoneNumber.normalize('00447700900123'), '+447700900123');
    });

    test('treats a leading 00 as the international prefix, not a trunk zero', () {
      // Must match functions/test/phone.test.js exactly. "00" is the
      // international access code, so these two strings — one character apart
      // — resolve to different countries.
      expect(PhoneNumber.normalize('00821234567'), '+821234567');
      expect(PhoneNumber.normalize('0821234567'), '+27821234567');
    });

    test('is idempotent', () {
      final String? once = PhoneNumber.normalize('082 123 4567');
      expect(PhoneNumber.normalize(once), once);
    });

    test('rejects a number too short to be dialable', () {
      expect(PhoneNumber.normalize('+27 12'), isNull);
      expect(PhoneNumber.normalize('0 1 2'), isNull);
    });

    test('assumes dial code 27 for local-form numbers', () {
      // Part of the contract, not an implementation detail — it must match
      // DEFAULT_DIAL_CODE in functions/phone.js.
      expect(PhoneNumber.defaultDialCode, '27');
    });

    test('isValid agrees with normalize', () {
      for (final String? input in <String?>['082 123 4567', '+44 7700 900123', null, '', 'abc', '123']) {
        expect(PhoneNumber.isValid(input), PhoneNumber.normalize(input) != null, reason: 'input: $input');
      }
    });

    test('returns null for values that are not usable numbers', () {
      for (final String? input in <String?>[null, '', '   ', 'abc', '123']) {
        expect(PhoneNumber.normalize(input), isNull, reason: 'input: $input');
      }
    });
  });

  group('PhoneNumber.matches', () {
    test('matches the same subscriber written differently', () {
      expect(PhoneNumber.matches('082 123 4567', '+27821234567'), isTrue);
    });

    test('does not match different subscribers', () {
      expect(PhoneNumber.matches('082 123 4567', '082 123 4568'), isFalse);
    });

    test('two unusable values never match each other', () {
      expect(PhoneNumber.matches('', ''), isFalse);
      expect(PhoneNumber.matches(null, null), isFalse);
    });
  });
}
