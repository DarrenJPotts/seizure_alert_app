class AlertResponseDto {
  final String id;
  final String alertId;
  final String contactId;
  final String contactName;
  final bool seen;
  final bool responding;
  final DateTime? seenAt;
  final DateTime? respondedAt;

  AlertResponseDto({
    required this.id,
    required this.alertId,
    required this.contactId,
    required this.contactName,
    this.seen = false,
    this.responding = false,
    this.seenAt,
    this.respondedAt,
  });

  factory AlertResponseDto.fromMap(Map<String, dynamic> map) => AlertResponseDto(
    id: map['id'] as String,
    alertId: map['alertId'] as String,
    contactId: map['contactId'] as String,
    contactName: map['contactName'] as String,
    seen: map['seen'] as bool? ?? false,
    responding: map['responding'] as bool? ?? false,
    seenAt: map['seenAt'] != null ? DateTime.parse(map['seenAt'] as String) : null,
    respondedAt: map['respondedAt'] != null ? DateTime.parse(map['respondedAt'] as String) : null,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'alertId': alertId,
    'contactId': contactId,
    'contactName': contactName,
    'seen': seen,
    'responding': responding,
    'seenAt': seenAt?.toIso8601String(),
    'respondedAt': respondedAt?.toIso8601String(),
  };
}