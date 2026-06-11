// lib/core/dtos/heads_up_dto.dart

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

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
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