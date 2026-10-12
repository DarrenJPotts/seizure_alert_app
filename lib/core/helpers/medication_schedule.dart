import 'package:timezone/timezone.dart' as tz;

/// Uses calendar days so daylight-saving changes preserve the selected time.
tz.TZDateTime nextMedicationReminder({
  required tz.TZDateTime now,
  required int hour,
  required int minute,
}) {
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    throw ArgumentError('Invalid reminder time');
  }
  final today = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (today.isAfter(now)) return today;
  return tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day + 1,
    hour,
    minute,
  );
}
