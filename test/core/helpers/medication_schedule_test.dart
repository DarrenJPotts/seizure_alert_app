import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/helpers/medication_schedule.dart';
import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(data.initializeTimeZones);

  test('uses today when the selected time is still ahead', () {
    final zone = tz.getLocation('Asia/Tokyo');
    final result = nextMedicationReminder(
      now: tz.TZDateTime(zone, 2026, 10, 12, 7),
      hour: 8,
      minute: 15,
    );
    expect(result, tz.TZDateTime(zone, 2026, 10, 12, 8, 15));
  });

  test('rolls over year at the selected wall-clock time', () {
    final zone = tz.getLocation('Africa/Johannesburg');
    expect(
      nextMedicationReminder(
        now: tz.TZDateTime(zone, 2026, 12, 31, 8),
        hour: 8,
        minute: 0,
      ),
      tz.TZDateTime(zone, 2027, 1, 1, 8),
    );
  });

  test('spring DST change advances 23 hours while preserving 08:00', () {
    final zone = tz.getLocation('America/New_York');
    final now = tz.TZDateTime(zone, 2026, 3, 7, 8);
    final result = nextMedicationReminder(now: now, hour: 8, minute: 0);
    expect(result, tz.TZDateTime(zone, 2026, 3, 8, 8));
    expect(result.difference(now), const Duration(hours: 23));
  });

  test('autumn DST change advances 25 hours while preserving 08:00', () {
    final zone = tz.getLocation('America/New_York');
    final now = tz.TZDateTime(zone, 2026, 10, 31, 8);
    final result = nextMedicationReminder(now: now, hour: 8, minute: 0);
    expect(result, tz.TZDateTime(zone, 2026, 11, 1, 8));
    expect(result.difference(now), const Duration(hours: 25));
  });

  test('rejects invalid reminder times', () {
    final now = tz.TZDateTime(tz.UTC, 2026);
    expect(
      () => nextMedicationReminder(now: now, hour: 24, minute: 0),
      throwsArgumentError,
    );
    expect(
      () => nextMedicationReminder(now: now, hour: 8, minute: -1),
      throwsArgumentError,
    );
  });
}
