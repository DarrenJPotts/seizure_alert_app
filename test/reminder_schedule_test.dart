import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/dtos/medication_reminder_dto.dart';
import 'package:seizure_app/core/helpers/reminder_schedule.dart';
import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

MedicationReminderDto reminder({
  ReminderRepeat repeat = ReminderRepeat.daily,
  DateTime? start,
  List<int> days = const [],
  int monthDay = 1,
}) => MedicationReminderDto(
  id: 'vitamins',
  name: 'Take vitamins',
  kind: ReminderKind.supplement,
  repeat: repeat,
  hour: 9,
  minute: 0,
  startDate: start,
  weekdays: days,
  monthDay: monthDay,
);

void main() {
  setUpAll(data.initializeTimeZones);
  test('legacy daily records retain name, dose, enable state and time', () {
    final old = MedicationReminderDto.fromMap({
      'id': 'old',
      'name': 'Prescription',
      'dose': 'Recorded dose',
      'hour': 8,
      'minute': 15,
      'enabled': false,
    });
    expect(old.repeat, ReminderRepeat.daily);
    expect(old.kind, ReminderKind.medication);
    expect(old.history, isEmpty);
    expect(old.copyWith(enabled: true).dose, 'Recorded dose');
    expect(MedicationReminderDto.fromMap(old.toMap()).enabled, isFalse);
  });
  test('weekly Sunday vitamins at 09:00 advances to the next Sunday', () {
    final r = reminder(repeat: ReminderRepeat.weekly, days: [7]);
    expect(
      nextReminderOccurrence(r, DateTime(2026, 10, 22, 10)),
      DateTime(2026, 10, 25, 9),
    );
    expect(
      nextReminderOccurrence(r, DateTime(2026, 10, 25, 9)),
      DateTime(2026, 11, 1, 9),
    );
    expect(reminderScheduleLabel(r), 'Sun · 09:00');
  });
  test('selected weekdays produce separate recurring slots', () {
    final r = reminder(repeat: ReminderRepeat.weekdays, days: [1, 3, 5]);
    final slots = reminderNotificationSlots([r], DateTime(2026, 10, 22, 10));
    expect(slots.map((s) => s.at.weekday).toList()..sort(), [1, 3, 5]);
    expect(slots.every((s) => s.repeat == ReminderRepeat.weekly), isTrue);
    expect(slots.map((s) => s.key).toSet().length, 3);
  });
  test('one-off reminders do not recur and wait until their start date', () {
    final r = reminder(
      repeat: ReminderRepeat.once,
      start: DateTime(2027, 4, 6),
    );
    expect(
      nextReminderOccurrence(r, DateTime(2026, 10, 22)),
      DateTime(2027, 4, 6, 9),
    );
    expect(latestReminderOccurrence(r, DateTime(2027, 4, 6, 8)), isNull);
    expect(nextReminderOccurrence(r, DateTime(2027, 4, 6, 10)), isNull);
    expect(
      actionableReminderOccurrence(r, DateTime(2027, 4, 6, 10)),
      DateTime(2027, 4, 6, 9),
    );
  });
  test('monthly 31 skips short months, including February', () {
    final r = reminder(repeat: ReminderRepeat.monthly, monthDay: 31);
    expect(
      nextReminderOccurrence(r, DateTime(2026, 1, 31, 10)),
      DateTime(2026, 3, 31, 9),
    );
    expect(
      nextReminderOccurrence(r, DateTime(2026, 4, 1)),
      DateTime(2026, 5, 31, 9),
    );
    final leap = reminder(repeat: ReminderRepeat.monthly, monthDay: 29);
    expect(
      nextReminderOccurrence(leap, DateTime(2028, 2, 1)),
      DateTime(2028, 2, 29, 9),
    );
  });
  test('future start dates prevent earlier daily or weekly occurrences', () {
    final r = reminder(start: DateTime(2027, 1, 1));
    expect(
      nextReminderOccurrence(r, DateTime(2026, 10, 22)),
      DateTime(2027, 1, 1, 9),
    );
    expect(latestReminderOccurrence(r, DateTime(2026, 12, 31)), isNull);
  });
  test('DST uses calendar days rather than 24-hour increments', () {
    final zone = tz.getLocation('America/New_York');
    final now = tz.TZDateTime(zone, 2026, 3, 7, 9);
    final next = nextReminderOccurrence(reminder(), now)!;
    expect(next, tz.TZDateTime(zone, 2026, 3, 8, 9));
    expect(next.difference(now), const Duration(hours: 23));
    final autumn = tz.TZDateTime(zone, 2026, 10, 31, 9);
    expect(
      nextReminderOccurrence(reminder(), autumn)!.difference(autumn),
      const Duration(hours: 25),
    );
  });
  test('completed and skipped occurrences cannot be actioned twice', () {
    final now = DateTime(2026, 10, 22, 10);
    for (final action in [ReminderAction.completed, ReminderAction.skipped]) {
      final r = reminder().copyWith(
        history: [
          ReminderEvent(
            occurrence: reminderOccurrenceKey(DateTime(2026, 10, 22, 9)),
            at: now,
            action: action,
          ),
        ],
      );
      expect(actionableReminderOccurrence(r, now), isNull);
      expect(nextReminderOccurrence(r, now), DateTime(2026, 10, 23, 9));
      expect(
        actionableReminderOccurrence(r, DateTime(2026, 10, 23, 10)),
        DateTime(2026, 10, 23, 9),
      );
    }
  });
  test('snooze adds one future alert and disappears after completion', () {
    final now = DateTime(2026, 10, 22, 10);
    final key = reminderOccurrenceKey(DateTime(2026, 10, 22, 9));
    final r = reminder().copyWith(
      snoozedUntil: now.add(const Duration(minutes: 15)),
      snoozedOccurrence: key,
    );
    final slots = reminderNotificationSlots([r], now);
    expect(slots.length, 2);
    expect(slots.last.at, now.add(const Duration(minutes: 15)));
    expect(slots.last.repeat, ReminderRepeat.once);
    final done = r.copyWith(
      history: [
        ReminderEvent(
          occurrence: key,
          at: now,
          action: ReminderAction.completed,
        ),
      ],
      clearSnooze: true,
    );
    expect(reminderNotificationSlots([done], now).length, 1);
    expect(
      MedicationReminderDto.fromMap(
        r.toMap(),
      ).snoozedUntil!.isAtSameMomentAs(r.snoozedUntil!),
      isTrue,
    );
  });
  test('disabled reminders have no native schedules or action controls', () {
    final r = reminder().copyWith(enabled: false);
    expect(reminderNotificationSlots([r], DateTime(2026, 10, 22, 10)), isEmpty);
    expect(actionableReminderOccurrence(r, DateTime(2026, 10, 22, 10)), isNull);
  });
  test(
    'invalid weekday selections and pending schedule overflow are rejected',
    () {
      expect(
        reminder(repeat: ReminderRepeat.weekdays).validationError,
        isNotNull,
      );
      expect(
        reminder(repeat: ReminderRepeat.weekly, days: [1, 2]).validationError,
        isNotNull,
      );
      final allWeek = [
        for (var i = 0; i < 9; i++)
          MedicationReminderDto(
            id: '$i',
            name: 'Reminder',
            hour: 9,
            minute: 0,
            repeat: ReminderRepeat.weekdays,
            weekdays: [1, 2, 3, 4, 5, 6, 7],
          ),
      ];
      expect(
        () => reminderNotificationSlots(allWeek, DateTime(2026, 10, 22)),
        throwsStateError,
      );
    },
  );
}
