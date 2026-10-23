import 'package:timezone/timezone.dart' as tz;
import 'package:seizure_app/core/dtos/medication_reminder_dto.dart';

DateTime _wallTime(
  DateTime reference,
  int year,
  int month,
  int day,
  int hour,
  int minute,
) => reference is tz.TZDateTime
    ? tz.TZDateTime(reference.location, year, month, day, hour, minute)
    : DateTime(year, month, day, hour, minute);

String reminderOccurrenceKey(DateTime at) =>
    DateTime(at.year, at.month, at.day, at.hour, at.minute).toIso8601String();

bool _matches(MedicationReminderDto reminder, DateTime date, int? weekday) {
  final start = reminder.startDate;
  final civil = DateTime(date.year, date.month, date.day);
  if (start != null &&
      civil.isBefore(DateTime(start.year, start.month, start.day))) {
    return false;
  }
  if (weekday != null && date.weekday != weekday) return false;
  return switch (reminder.repeat) {
    ReminderRepeat.once =>
      start != null && civil == DateTime(start.year, start.month, start.day),
    ReminderRepeat.daily => true,
    ReminderRepeat.weekdays ||
    ReminderRepeat.weekly => reminder.weekdays.contains(date.weekday),
    ReminderRepeat.monthly => date.day == reminder.monthDay,
  };
}

/// Monthly day 29–31 skips months in which that calendar date does not exist.
/// Calendar arithmetic preserves wall-clock time across daylight-saving changes.
DateTime? nextReminderOccurrence(
  MedicationReminderDto reminder,
  DateTime now, {
  int? weekday,
}) {
  if (!reminder.enabled || reminder.validationError != null) return null;
  var base = now;
  final start = reminder.startDate;
  if (start != null &&
      DateTime(
        start.year,
        start.month,
        start.day,
      ).isAfter(DateTime(now.year, now.month, now.day))) {
    base = _wallTime(now, start.year, start.month, start.day, 0, 0);
  }
  for (var i = 0; i <= 366; i++) {
    final at = _wallTime(
      now,
      base.year,
      base.month,
      base.day + i,
      reminder.hour,
      reminder.minute,
    );
    if (at.isAfter(now) &&
        _matches(reminder, at, weekday) &&
        !reminder.isResolved(reminderOccurrenceKey(at))) {
      return at;
    }
    if (reminder.repeat == ReminderRepeat.once && i > 0) break;
  }
  return null;
}

DateTime? latestReminderOccurrence(
  MedicationReminderDto reminder,
  DateTime now,
) {
  if (!reminder.enabled || reminder.validationError != null) return null;
  for (var i = 0; i <= 366; i++) {
    final at = _wallTime(
      now,
      now.year,
      now.month,
      now.day - i,
      reminder.hour,
      reminder.minute,
    );
    if (!at.isAfter(now) && _matches(reminder, at, null)) return at;
  }
  return null;
}

DateTime? actionableReminderOccurrence(
  MedicationReminderDto reminder,
  DateTime now,
) {
  final latest = latestReminderOccurrence(reminder, now);
  return latest == null || reminder.isResolved(reminderOccurrenceKey(latest))
      ? null
      : latest;
}

String reminderScheduleLabel(MedicationReminderDto reminder) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final time =
      '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}';
  final repeat = switch (reminder.repeat) {
    ReminderRepeat.once =>
      reminder.startDate == null
          ? 'Once'
          : '${reminder.startDate!.day}/${reminder.startDate!.month}/${reminder.startDate!.year}',
    ReminderRepeat.daily => 'Every day',
    ReminderRepeat.weekdays || ReminderRepeat.weekly =>
      reminder.weekdays
          .where((d) => d >= 1 && d <= 7)
          .map((d) => days[d - 1])
          .join(', '),
    ReminderRepeat.monthly => 'Day ${reminder.monthDay} of each month',
  };
  return '$repeat · $time';
}

typedef ReminderNotificationSlot = ({
  String key,
  MedicationReminderDto reminder,
  DateTime at,
  ReminderRepeat repeat,
});

List<ReminderNotificationSlot> reminderNotificationSlots(
  List<MedicationReminderDto> reminders,
  DateTime now,
) {
  final slots = <ReminderNotificationSlot>[];
  for (final reminder in reminders) {
    if (reminder.validationError != null) {
      throw ArgumentError(reminder.validationError);
    }
    if (!reminder.enabled) continue;
    if (reminder.repeat == ReminderRepeat.weekdays ||
        reminder.repeat == ReminderRepeat.weekly) {
      for (final day in reminder.weekdays.toSet()) {
        final at = nextReminderOccurrence(reminder, now, weekday: day);
        if (at != null) {
          slots.add((
            key: '${reminder.id}:weekday:$day',
            reminder: reminder,
            at: at,
            repeat: ReminderRepeat.weekly,
          ));
        }
      }
    } else {
      final at = nextReminderOccurrence(reminder, now);
      if (at != null) {
        slots.add((
          key: reminder.id,
          reminder: reminder,
          at: at,
          repeat: reminder.repeat,
        ));
      }
    }
    final snooze = reminder.snoozedUntil;
    final due = actionableReminderOccurrence(reminder, now);
    if (snooze != null &&
        snooze.isAfter(now) &&
        due != null &&
        reminderOccurrenceKey(due) == reminder.snoozedOccurrence) {
      slots.add((
        key: '${reminder.id}:snooze',
        reminder: reminder,
        at: snooze,
        repeat: ReminderRepeat.once,
      ));
    }
  }
  // Leave space for emergency notifications within iOS's pending-request limit.
  if (slots.length > 60) {
    throw StateError(
      'Too many scheduled days. Reduce the number of enabled reminders.',
    );
  }
  return slots;
}
