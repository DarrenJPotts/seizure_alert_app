import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/helpers/timestamps.dart';

void main() {
  test('writes UTC with a Z suffix', () {
    final DateTime local = DateTime(2026, 11, 23, 10, 30);
    final String stored = toStoredTimestamp(local);
    expect(stored.endsWith('Z'), isTrue);
    expect(DateTime.parse(stored).isAtSameMomentAs(local), isTrue);
  });

  test('reads UTC back as the same moment in local time', () {
    final DateTime local = DateTime(2026, 11, 23, 10, 30);
    final DateTime read = parseStoredTimestamp(toStoredTimestamp(local));
    expect(read.isUtc, isFalse);
    expect(read, local);
  });

  test('reads an old local string without an offset as local time', () {
    final DateTime read = parseStoredTimestamp('2026-11-23T10:30:00.000');
    expect(read.isUtc, isFalse);
    expect(read.hour, 10);
  });

  test('server UTC and phone local values for the same moment agree', () {
    final DateTime moment = DateTime(2026, 11, 23, 0, 30);
    final DateTime fromServer = parseStoredTimestamp(
      moment.toUtc().toIso8601String(),
    );
    final DateTime fromOldPhone = parseStoredTimestamp(
      moment.toIso8601String(),
    );
    expect(fromServer, fromOldPhone);
    expect(fromServer.day, 23, reason: 'a 00:30 seizure stays on its own day');
  });

  test('tryParse handles missing and bad values', () {
    expect(tryParseStoredTimestamp(null), isNull);
    expect(tryParseStoredTimestamp(''), isNull);
    expect(tryParseStoredTimestamp('not a date'), isNull);
    expect(tryParseStoredTimestamp(42), isNull);
    expect(tryParseStoredTimestamp('2026-11-23T08:30:00.000Z')?.isUtc, isFalse);
  });
}
