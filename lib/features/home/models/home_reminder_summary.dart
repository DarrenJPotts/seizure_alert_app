import 'package:seizure_app/core/dtos/medication_reminder_dto.dart';
import 'package:seizure_app/core/helpers/reminder_schedule.dart';

typedef HomeReminderSummary = ({
  MedicationReminderDto reminder,
  DateTime at,
  bool snoozed,
});

HomeReminderSummary? homeReminderSummary(
  List<MedicationReminderDto> reminders,
  DateTime now,
) {
  final candidates = <HomeReminderSummary>[];
  for (final reminder in reminders) {
    final due = actionableReminderOccurrence(reminder, now);
    final snoozed =
        due != null &&
        reminder.snoozedUntil?.isAfter(now) == true &&
        reminder.snoozedOccurrence == reminderOccurrenceKey(due);
    final at = snoozed
        ? reminder.snoozedUntil
        : due ?? nextReminderOccurrence(reminder, now);
    if (at != null) {
      candidates.add((reminder: reminder, at: at, snoozed: snoozed));
    }
  }
  candidates.sort((a, b) {
    final order = a.at.compareTo(b.at);
    return order == 0 ? a.reminder.id.compareTo(b.reminder.id) : order;
  });
  return candidates.firstOrNull;
}
