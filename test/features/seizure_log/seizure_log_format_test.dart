import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/features/seizure_log/widgets/seizure_log_row.dart';

/// Formatting for the seizure log, moved out of the old `SeizureLogCard` when
/// the screen adopted the grouped-card language. These strings are the whole
/// content of the list, and the relative ones ("Today", "Yesterday", "This
/// month") are the kind that quietly go wrong across a day or year boundary.
void main() {
  SeizureLogDto log({
    DateTime? occurredAt,
    int? durationSeconds,
    String? location,
    bool alertFired = false,
  }) => SeizureLogDto(
    id: 'l',
    userId: 'u',
    occurredAt: occurredAt ?? DateTime(2026, 3, 14, 9, 30),
    durationSeconds: durationSeconds,
    location: location,
    alertFired: alertFired,
  );

  group('formatLogDate', () {
    final DateTime now = DateTime(2026, 3, 14, 18, 0);

    test('uses relative wording for today and yesterday', () {
      expect(formatLogDate(DateTime(2026, 3, 14, 9, 30), now: now), 'Today, 9:30 AM');
      expect(formatLogDate(DateTime(2026, 3, 13, 23, 5), now: now), 'Yesterday, 11:05 PM');
    });

    test('falls back to an absolute date beyond yesterday', () {
      expect(formatLogDate(DateTime(2026, 3, 12, 14, 0), now: now), 'Mar 12, 2:00 PM');
      expect(formatLogDate(DateTime(2025, 12, 1, 7, 45), now: now), 'Dec 1, 7:45 AM');
    });

    test('compares calendar days, not elapsed hours', () {
      // 23:50 last night is "Yesterday" even though it is under 24h ago, and
      // 00:10 this morning is "Today" even though it is barely past midnight.
      expect(formatLogDate(DateTime(2026, 3, 13, 23, 50), now: now), startsWith('Yesterday'));
      expect(formatLogDate(DateTime(2026, 3, 14, 0, 10), now: now), startsWith('Today'));
    });

    test('renders midnight and noon as 12, not 0', () {
      expect(formatLogDate(DateTime(2026, 3, 14, 0, 0), now: now), 'Today, 12:00 AM');
      expect(formatLogDate(DateTime(2026, 3, 14, 12, 0), now: now), 'Today, 12:00 PM');
    });
  });

  group('formatLogDuration', () {
    test('shows seconds under a minute', () {
      expect(formatLogDuration(45), '~45s');
      expect(formatLogDuration(0), '~0s');
    });

    test('drops seconds when they are exactly zero', () {
      expect(formatLogDuration(120), '~2m');
    });

    test('shows both parts otherwise', () {
      expect(formatLogDuration(150), '~2m 30s');
      expect(formatLogDuration(3661), '~61m 1s');
    });
  });

  group('logSubtitle', () {
    test('joins duration and location', () {
      expect(logSubtitle(log(durationSeconds: 150, location: 'Kitchen')), '~2m 30s · Kitchen');
    });

    test('shows whichever part is recorded', () {
      expect(logSubtitle(log(durationSeconds: 90)), '~1m 30s');
      expect(logSubtitle(log(location: 'Office')), 'Office');
    });

    test('says so when nothing was recorded', () {
      expect(logSubtitle(log()), 'No details recorded');
      // A zero duration means "not timed", not "lasted zero seconds".
      expect(logSubtitle(log(durationSeconds: 0)), 'No details recorded');
      expect(logSubtitle(log(location: '   ')), 'No details recorded');
    });
  });

  group('formatLogMonth', () {
    final DateTime now = DateTime(2026, 3, 14);

    test('names the current month relatively', () {
      expect(formatLogMonth(DateTime(2026, 3, 1), now: now), 'This month');
    });

    test('names other months in the current year without the year', () {
      expect(formatLogMonth(DateTime(2026, 2, 28), now: now), 'February');
      expect(formatLogMonth(DateTime(2026, 12, 1), now: now), 'December');
    });

    test('adds the year once it differs', () {
      expect(formatLogMonth(DateTime(2025, 3, 31), now: now), 'March 2025');
      expect(formatLogMonth(DateTime(2025, 12, 25), now: now), 'December 2025');
    });

    test('does not treat the same month a year earlier as "This month"', () {
      // The bug this guards: matching on month alone.
      expect(formatLogMonth(DateTime(2025, 3, 14), now: now), isNot('This month'));
    });
  });
}
