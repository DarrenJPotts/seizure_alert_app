enum ReminderKind { medication, supplement, appointment, custom }

enum ReminderRepeat { once, daily, weekdays, weekly, monthly }

enum ReminderAction { completed, skipped, snoozed }

class ReminderEvent {
  const ReminderEvent({
    required this.occurrence,
    required this.at,
    required this.action,
  });
  final String occurrence;
  final DateTime at;
  final ReminderAction action;

  Map<String, dynamic> toMap() => {
    'occurrence': occurrence,
    'at': at.toUtc().toIso8601String(),
    'action': action.name,
  };
  static ReminderEvent? tryParse(Map map) {
    final at = DateTime.tryParse(map['at']?.toString() ?? '');
    final occurrence = map['occurrence']?.toString() ?? '';
    final action = ReminderAction.values
        .where((e) => e.name == map['action'])
        .firstOrNull;
    if (at == null || DateTime.tryParse(occurrence) == null || action == null) {
      return null;
    }
    return ReminderEvent(occurrence: occurrence, at: at, action: action);
  }
}

/// Retains the legacy name and Firestore field to migrate existing daily reminders.
class MedicationReminderDto {
  const MedicationReminderDto({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    this.dose,
    this.enabled = true,
    this.kind = ReminderKind.medication,
    this.repeat = ReminderRepeat.daily,
    this.startDate,
    this.weekdays = const [],
    this.monthDay = 1,
    this.history = const [],
    this.snoozedUntil,
    this.snoozedOccurrence,
    this.revision = 0,
  });

  final String id;
  final String name;
  final String? dose;
  final int hour;
  final int minute;
  final bool enabled;
  final ReminderKind kind;
  final ReminderRepeat repeat;
  final DateTime? startDate;
  final List<int> weekdays;
  final int monthDay;
  final List<ReminderEvent> history;
  final DateTime? snoozedUntil;
  final String? snoozedOccurrence;
  final int revision;

  bool get isMedicine =>
      kind == ReminderKind.medication || kind == ReminderKind.supplement;
  String get kindLabel => switch (kind) {
    ReminderKind.medication => 'Medication',
    ReminderKind.supplement => 'Vitamin / supplement',
    ReminderKind.appointment => 'Appointment',
    ReminderKind.custom => 'Custom',
  };
  String? get validationError {
    if (id.isEmpty ||
        name.trim().isEmpty ||
        name.length > 100 ||
        (dose?.length ?? 0) > 100) {
      return 'Enter a name of up to 100 characters.';
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return 'Choose a valid time.';
    }
    if (repeat == ReminderRepeat.once && startDate == null) {
      return 'Choose a date.';
    }
    if ((repeat == ReminderRepeat.weekdays ||
            repeat == ReminderRepeat.weekly) &&
        (weekdays.isEmpty ||
            weekdays.any((d) => d < 1 || d > 7) ||
            (repeat == ReminderRepeat.weekly &&
                weekdays.toSet().length != 1))) {
      return 'Choose the days for this reminder.';
    }
    if (repeat == ReminderRepeat.monthly && (monthDay < 1 || monthDay > 31)) {
      return 'Choose a day from 1 to 31.';
    }
    return null;
  }

  bool isResolved(String occurrence) => history.any(
    (e) => e.occurrence == occurrence && e.action != ReminderAction.snoozed,
  );

  factory MedicationReminderDto.fromMap(
    Map<String, dynamic> map,
  ) => MedicationReminderDto(
    id: map['id'] as String,
    name: map['name'] as String,
    dose: map['dose'] as String?,
    hour: map['hour'] as int? ?? 8,
    minute: map['minute'] as int? ?? 0,
    enabled: map['enabled'] as bool? ?? true,
    kind:
        ReminderKind.values.where((e) => e.name == map['kind']).firstOrNull ??
        ReminderKind.medication,
    repeat:
        ReminderRepeat.values
            .where((e) => e.name == map['repeat'])
            .firstOrNull ??
        ReminderRepeat.daily,
    startDate: DateTime.tryParse(map['startDate']?.toString() ?? ''),
    weekdays: (map['weekdays'] as List? ?? []).whereType<int>().toSet().toList()
      ..sort(),
    monthDay: map['monthDay'] as int? ?? 1,
    history: (map['history'] as List? ?? [])
        .whereType<Map>()
        .map(ReminderEvent.tryParse)
        .whereType<ReminderEvent>()
        .take(100)
        .toList(),
    snoozedUntil: DateTime.tryParse(map['snoozedUntil']?.toString() ?? ''),
    snoozedOccurrence: map['snoozedOccurrence'] as String?,
    revision: map['revision'] as int? ?? 0,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'dose': dose,
    'hour': hour,
    'minute': minute,
    'enabled': enabled,
    'kind': kind.name,
    'repeat': repeat.name,
    'startDate': startDate == null
        ? null
        : DateTime(
            startDate!.year,
            startDate!.month,
            startDate!.day,
          ).toIso8601String(),
    'weekdays': weekdays,
    'monthDay': monthDay,
    'history': history.take(100).map((e) => e.toMap()).toList(),
    'snoozedUntil': snoozedUntil?.toUtc().toIso8601String(),
    'snoozedOccurrence': snoozedOccurrence,
    'revision': revision,
  };

  MedicationReminderDto copyWith({
    bool? enabled,
    List<ReminderEvent>? history,
    DateTime? snoozedUntil,
    String? snoozedOccurrence,
    bool clearSnooze = false,
    int? revision,
  }) => MedicationReminderDto(
    id: id,
    name: name,
    dose: dose,
    hour: hour,
    minute: minute,
    enabled: enabled ?? this.enabled,
    kind: kind,
    repeat: repeat,
    startDate: startDate,
    weekdays: weekdays,
    monthDay: monthDay,
    history: history ?? this.history,
    snoozedUntil: clearSnooze ? null : snoozedUntil ?? this.snoozedUntil,
    snoozedOccurrence: clearSnooze
        ? null
        : snoozedOccurrence ?? this.snoozedOccurrence,
    revision: revision ?? this.revision,
  );
}
