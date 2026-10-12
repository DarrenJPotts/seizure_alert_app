class SeizureLogDto {
  final String id;
  final String userId;
  final DateTime occurredAt;
  final int? durationSeconds;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String? trigger;
  final String? seizureType;
  final String? aura;
  final String? severity;
  final String? awareness;
  final String? injuries;
  final int? recoveryMinutes;
  final bool rescueMedicationUsed;
  final bool alertFired;
  final String? alertId;

  SeizureLogDto({
    required this.id,
    required this.userId,
    required this.occurredAt,
    this.durationSeconds,
    this.location,
    this.latitude,
    this.longitude,
    this.notes,
    this.trigger,
    this.seizureType,
    this.aura,
    this.severity,
    this.awareness,
    this.injuries,
    this.recoveryMinutes,
    this.rescueMedicationUsed = false,
    this.alertFired = false,
    this.alertId,
  });

  factory SeizureLogDto.fromMap(Map<String, dynamic> map) => SeizureLogDto(
    id: map['id'] as String,
    userId: map['userId'] as String,
    occurredAt: DateTime.parse(map['occurredAt'] as String),
    durationSeconds: map['durationSeconds'] as int?,
    location: map['location'] as String?,
    latitude: (map['latitude'] as num?)?.toDouble(),
    longitude: (map['longitude'] as num?)?.toDouble(),
    notes: map['notes'] as String?,
    trigger: map['trigger'] as String?,
    seizureType: map['seizureType'] as String?,
    aura: map['aura'] as String?,
    severity: map['severity'] as String?,
    awareness: map['awareness'] as String?,
    injuries: map['injuries'] as String?,
    recoveryMinutes: map['recoveryMinutes'] as int?,
    rescueMedicationUsed: map['rescueMedicationUsed'] as bool? ?? false,
    alertFired: map['alertFired'] as bool? ?? false,
    alertId: map['alertId'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'occurredAt': occurredAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'notes': notes,
    'trigger': trigger,
    'seizureType': seizureType,
    'aura': aura,
    'severity': severity,
    'awareness': awareness,
    'injuries': injuries,
    'recoveryMinutes': recoveryMinutes,
    'rescueMedicationUsed': rescueMedicationUsed,
    'alertFired': alertFired,
    'alertId': alertId,
  };
}
