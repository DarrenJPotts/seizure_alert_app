import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/features/analytics/models/analytics_summary.dart';

SeizureLogDto entry(DateTime at, {int? duration, int? recovery}) =>
    SeizureLogDto(
      id: at.toIso8601String(),
      userId: 'user',
      occurredAt: at,
      durationSeconds: duration,
      recoveryMinutes: recovery,
    );

void main() {
  test('duration labels preserve fractional medians', () {
    expect(AnalyticsSummary.durationText(60.5), '1 min 0.5 sec');
    expect(AnalyticsSummary.durationText(90), '1 min 30 sec');
    expect(AnalyticsSummary.durationText(null), 'Not recorded');
  });
  final now = DateTime(2026, 10, 21, 12);
  test('empty history has no invented duration or recovery', () {
    final stats = AnalyticsSummary([], now: now, days: 30);
    expect(stats.count, 0);
    expect(stats.previousCount, 0);
    expect(stats.medianDurationSeconds, isNull);
    expect(stats.medianRecoveryMinutes, isNull);
    expect(stats.comparison, contains('No recorded events'));
    expect(stats.frequency.every((bucket) => bucket.count == 0), isTrue);
  });
  for (final days in [30, 90]) {
    test(
      '$days-day windows include boundaries once and exclude future records',
      () {
        final start = DateTime(now.year, now.month, now.day - days + 1);
        final previous = DateTime(start.year, start.month, start.day - days);
        final stats = AnalyticsSummary(
          [
            entry(previous.subtract(const Duration(microseconds: 1))),
            entry(previous),
            entry(start.subtract(const Duration(microseconds: 1))),
            entry(start),
            entry(now),
            entry(now.add(const Duration(microseconds: 1))),
          ],
          now: now,
          days: days,
        );
        expect(stats.count, 2);
        expect(stats.previousCount, 2);
        expect(
          stats.frequency.map((bucket) => bucket.count).reduce((a, b) => a + b),
          2,
        );
        expect(stats.comparison, startsWith('Same recorded count'));
      },
    );
  }
  test(
    'medians exclude missing or invalid values while zero recovery is valid',
    () {
      final stats = AnalyticsSummary(
        [
          entry(now, duration: 10, recovery: 0),
          entry(now, duration: 30, recovery: 20),
          entry(now, duration: null),
          entry(now, duration: 0),
          entry(now, duration: -1, recovery: -5),
        ],
        now: now,
        days: 30,
      );
      expect(stats.count, 5);
      expect(stats.durationCount, 2);
      expect(stats.medianDurationSeconds, 20);
      expect(stats.longestDurationSeconds, 30);
      expect(stats.recoveryCount, 2);
      expect(stats.medianRecoveryMinutes, 10);
    },
  );
  test(
    'odd median and local time-of-day buckets use actual recorded events',
    () {
      final stats = AnalyticsSummary(
        [
          entry(DateTime(2026, 10, 20, 5, 59), duration: 10),
          entry(DateTime(2026, 10, 20, 6), duration: 31),
          entry(DateTime(2026, 10, 20, 12), duration: 80),
          entry(DateTime(2026, 10, 20, 18)),
        ],
        now: now,
        days: 30,
      );
      expect(stats.medianDurationSeconds, 31);
      expect(stats.timeOfDay.map((bucket) => bucket.count), [1, 1, 1, 1]);
    },
  );
  test('longer period includes older records and handles zero baseline', () {
    final stats = AnalyticsSummary(
      [entry(DateTime(2026, 8, 25))],
      now: now,
      days: 90,
    );
    expect(stats.count, 1);
    expect(stats.comparison, contains('No recorded events'));
    expect(
      AnalyticsSummary(
        [entry(DateTime(2026, 8, 25))],
        now: now,
        days: 30,
      ).count,
      0,
    );
  });
  test(
    'unsupported periods are rejected',
    () => expect(
      () => AnalyticsSummary([], now: now, days: 0),
      throwsArgumentError,
    ),
  );
}
