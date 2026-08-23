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
