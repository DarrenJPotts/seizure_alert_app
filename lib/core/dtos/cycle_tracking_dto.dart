DateTime cycleDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

enum CycleFlow {
  notRecorded('Not recorded'),
  spotting('Spotting'),
  light('Light'),
  medium('Medium'),
  heavy('Heavy');

  const CycleFlow(this.label);
  final String label;
}

class CycleEntryDto {
  const CycleEntryDto({
    required this.id,
    required this.start,
    this.end,
    this.flow = CycleFlow.notRecorded,
    this.symptoms = '',
    this.notes = '',
  });
  final String id;
  final DateTime start;
  final DateTime? end;
  final CycleFlow flow;
  final String symptoms;
  final String notes;
  String? validate(DateTime now) {
    if (id.isEmpty || id.length > 100) {
      return 'Invalid entry. Close and try again.';
    }
    if (cycleDate(start).isAfter(cycleDate(now))) {
      return 'Start date cannot be in the future.';
    }
    if (end != null && cycleDate(end!).isBefore(cycleDate(start))) {
      return 'End date must be on or after the start date.';
    }
    if (end != null && cycleDate(end!).isAfter(cycleDate(now))) {
      return 'End date cannot be in the future.';
    }
    if (symptoms.length > 200 || notes.length > 500) {
      return 'Shorten the symptoms or notes.';
    }
    return null;
  }

  bool contains(DateTime date, DateTime now) =>
      !cycleDate(date).isBefore(cycleDate(start)) &&
      !cycleDate(date).isAfter(cycleDate(end ?? now));
  Map<String, dynamic> toMap() => {
    'id': id,
    'start': cycleDate(start).toIso8601String(),
    'end': end == null ? null : cycleDate(end!).toIso8601String(),
    'flow': flow.name,
    'symptoms': symptoms,
    'notes': notes,
  };
  factory CycleEntryDto.fromMap(Map<String, dynamic> map) => CycleEntryDto(
    id: map['id'] as String,
    start: DateTime.parse(map['start'] as String),
    end: map['end'] == null ? null : DateTime.parse(map['end'] as String),
    flow:
        CycleFlow.values
            .where((value) => value.name == map['flow'])
            .firstOrNull ??
        CycleFlow.notRecorded,
    symptoms: map['symptoms'] as String? ?? '',
    notes: map['notes'] as String? ?? '',
  );
}

/// Kept outside UserDto so general profile and caregiver serializers cannot
/// accidentally disclose reproductive-health information.
class CycleTrackingDto {
  const CycleTrackingDto({
    this.enabled = false,
    this.entries = const [],
    this.revision = 0,
  });
  final bool enabled;
  final List<CycleEntryDto> entries;
  final int revision;
  CycleTrackingDto copyWith({bool? enabled, List<CycleEntryDto>? entries}) =>
      CycleTrackingDto(
        enabled: enabled ?? this.enabled,
        entries: entries ?? this.entries,
        revision: revision + 1,
      );
  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'entries': entries.map((entry) => entry.toMap()).toList(),
    'revision': revision,
  };
  factory CycleTrackingDto.fromMap(Map<String, dynamic>? map) => map == null
      ? const CycleTrackingDto()
      : CycleTrackingDto(
          enabled: map['enabled'] as bool? ?? false,
          entries: (map['entries'] as List? ?? [])
              .map(
                (entry) => CycleEntryDto.fromMap(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(),
          revision: map['revision'] as int? ?? 0,
        );
}
