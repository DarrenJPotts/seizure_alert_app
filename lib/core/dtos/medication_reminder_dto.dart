class MedicationReminderDto {
  const MedicationReminderDto({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    this.dose,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String? dose;
  final int hour;
  final int minute;
  final bool enabled;

  factory MedicationReminderDto.fromMap(Map<String, dynamic> map) =>
      MedicationReminderDto(
        id: map['id'] as String,
        name: map['name'] as String,
        dose: map['dose'] as String?,
        hour: map['hour'] as int? ?? 8,
        minute: map['minute'] as int? ?? 0,
        enabled: map['enabled'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'dose': dose,
    'hour': hour,
    'minute': minute,
    'enabled': enabled,
  };

  MedicationReminderDto copyWith({bool? enabled}) => MedicationReminderDto(
    id: id,
    name: name,
    dose: dose,
    hour: hour,
    minute: minute,
    enabled: enabled ?? this.enabled,
  );
}
