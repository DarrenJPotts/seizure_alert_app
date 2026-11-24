import 'package:seizure_app/core/helpers/timestamps.dart';

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

  bool get isActive =>
      status == HeadsUpStatus.active && DateTime.now().isBefore(expiresAt);

  Duration get remaining => expiresAt.difference(DateTime.now());

  factory HeadsUpDto.fromMap(Map<String, dynamic> map) {
    return HeadsUpDto(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      createdAt: parseStoredTimestamp(map['createdAt'] as String),
      expiresAt: parseStoredTimestamp(map['expiresAt'] as String),
      note: map['note'] as String?,
      status: HeadsUpStatus.values.firstWhere((e) => e.name == map['status']),
    );
  }

  ///
  /// The server schedules escalation from this UTC value because the display
  /// string may not include enough timezone information to compare safely.
  int get expiresAtMs => expiresAt.toUtc().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'createdAt': toStoredTimestamp(createdAt),
    'expiresAt': toStoredTimestamp(expiresAt),
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
