enum HeadsUpStatus { active, checkedIn, expired, escalated, cancelled }

class HeadsUpDto {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? note;
  final HeadsUpStatus status;

  HeadsUpDto({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.expiresAt,
    this.note,
    required this.status,
  });

  bool get isActive => status == HeadsUpStatus.active && DateTime.now().isBefore(expiresAt);

  Duration get remaining => expiresAt.difference(DateTime.now());

  factory HeadsUpDto.fromMap(Map<String, dynamic> map) {
    return HeadsUpDto(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      note: map['note'] as String?,
      status: HeadsUpStatus.values.firstWhere((e) => e.name == map['status']),
    );
  }

  /// Absolute expiry instant in epoch milliseconds.
  ///
  /// [expiresAt] is serialised with `toIso8601String()`, which for a local
  /// `DateTime` carries no timezone suffix — so the server cannot compare it
  /// against its own clock without guessing the writer's offset. The sweep
  /// that escalates missed check-ins (`expireHeadsUpWindows` in
  /// `functions/index.js`) queries this field instead, which is unambiguous.
  int get expiresAtMs => expiresAt.toUtc().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'expiresAtMs': expiresAtMs,
    'note': note,
    'status': status.name,
  };

  HeadsUpDto copyWith({HeadsUpStatus? status}) => HeadsUpDto(
    id: id,
    userId: userId,
    createdAt: createdAt,
    expiresAt: expiresAt,
    note: note,
    status: status ?? this.status,
  );
}
