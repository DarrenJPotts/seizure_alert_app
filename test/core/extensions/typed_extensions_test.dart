import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/extensions/generic_extensions.dart';
import 'package:seizure_app/core/extensions/typed_extensions.dart';

/// Returns an empty string typed as nullable, defeating type promotion.
String? nullableEmpty() => '';

void main() {
  group('NullableStringX', () {
    test('isNullOrEmpty treats null and empty the same', () {
      expect((null as String?).isNullOrEmpty, isTrue);
      expect(''.isNullOrEmpty, isTrue);
      expect('a'.isNullOrEmpty, isFalse);
    });

    test('isNullOrEmpty considers whitespace to be content', () {
      expect(' '.isNullOrEmpty, isFalse);
    });

    test('isNotNullOrEmpty is the exact inverse', () {
      for (final String? value in <String?>[null, '', ' ', 'a']) {
        expect(value.isNotNullOrEmpty, !value.isNullOrEmpty);
      }
    });

    test('capitalizeFirstLetter passes null and empty through', () {
      expect((null as String?).capitalizeFirstLetter, isNull);

      // Routed through a function so flow analysis cannot promote the value
      // back to a non-null String — a `String? x = ''` local would promote and
      // silently bind to the unguarded StringX extension instead.
      expect(nullableEmpty().capitalizeFirstLetter, isNull);
    });

    test('capitalizeFirstLetter uppercases only the first character', () {
      expect('darren'.capitalizeFirstLetter, 'Darren');
      expect('darren potts'.capitalizeFirstLetter, 'Darren potts');
      expect('Darren'.capitalizeFirstLetter, 'Darren');
    });

    test('trimNullable collapses a blank string to null', () {
      expect('   '.trimNullable(), isNull);
      expect((null as String?).trimNullable(), isNull);
      expect('  hello  '.trimNullable(), 'hello');
    });

    test('isSvg on a nullable string is false rather than throwing', () {
      expect((null as String?).isSvg, isFalse);
      expect('icon.svg'.isSvg, isTrue);
      expect('icon.png'.isSvg, isFalse);
    });
  });

  group('StringX', () {
    test('capitalizeFirstLetter and lowerCaseFirstLetter invert each other', () {
      expect('hello'.capitalizeFirstLetter, 'Hello');
      expect('Hello'.lowerCaseFirstLetter, 'hello');
    });

    test('KNOWN BUG: both throw on an empty non-null string', () {
      // StringX indexes [0] without a length check, so an empty String — which
      // binds to this extension rather than the guarded nullable one — throws
      // RangeError instead of returning ''. Nothing in lib/ calls these today,
      // which is the only reason it has not surfaced. This test pins the
      // current behaviour; delete it and assert '' once the guard is added.
      expect(() => ''.capitalizeFirstLetter, throwsRangeError);
      expect(() => ''.lowerCaseFirstLetter, throwsRangeError);
    });

    test('addFullStop appends unconditionally', () {
      expect('Done'.addFullStop(), 'Done.');
    });

    test('addTrailingDots is idempotent', () {
      expect('Loading'.addTrailingDots(3), 'Loading...');
      expect('Loading...'.addTrailingDots(3), 'Loading...', reason: 'already suffixed, so nothing is added');
    });

    test('removeWhiteSpaces strips every kind of whitespace', () {
      expect('082 123 4567'.removeWhiteSpaces, '08212 34567'.removeWhiteSpaces);
      expect(' a\tb\nc '.removeWhiteSpaces, 'abc');
    });

    test('toSentenceCase normalises each word', () {
      expect('TONIC CLONIC'.toSentenceCase, 'Tonic Clonic');
      expect('missed dose'.toSentenceCase, 'Missed Dose');
    });

    test('toSentenceCase survives double spaces', () {
      expect('a  b'.toSentenceCase, 'A  B');
    });

    test('whitespace and line-break helpers pad by the requested count', () {
      expect('x'.addLeadingWhiteSpace(2), '  x');
      expect('x'.addTrailingWhiteSpace(2), 'x  ');
      expect('x'.addLeadingLineBreak(1), '\nx');
      expect('x'.addTrailLineBreak(1), 'x\n');
    });
  });

  group('NullableIterableX', () {
    test('isNullOrEmpty treats null and empty the same', () {
      expect((null as List<int>?).isNullOrEmpty, isTrue);
      expect(<int>[].isNullOrEmpty, isTrue);
      expect(<int>[1].isNullOrEmpty, isFalse);
    });
  });

  group('GenericExtensions', () {
    test('isNull and isNotNull are inverses', () {
      const String? nothing = null;
      const int something = 1;

      expect(nothing.isNull, isTrue);
      expect(nothing.isNotNull, isFalse);
      expect(something.isNull, isFalse);
      expect(something.isNotNull, isTrue);
    });
  });

  group('ColorExtension', () {
    test('darken lowers lightness and lighten raises it', () {
      const Color base = Color(0xFF808080);

      expect(HSLColor.fromColor(base.darken()).lightness, lessThan(HSLColor.fromColor(base).lightness));
      expect(HSLColor.fromColor(base.lighten()).lightness, greaterThan(HSLColor.fromColor(base).lightness));
    });

    test('lightness clamps rather than overflowing at the extremes', () {
      expect(HSLColor.fromColor(const Color(0xFF000000).darken(0.5)).lightness, 0.0);
      expect(HSLColor.fromColor(const Color(0xFFFFFFFF).lighten(0.5)).lightness, 1.0);
    });
  });
}
