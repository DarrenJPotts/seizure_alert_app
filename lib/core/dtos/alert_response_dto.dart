class AlertResponseDto {
  final String id;
  final String alertId;

  /// uid of the person the alert belongs to.
  ///
  /// Denormalised from the alert purely so `firestore.rules` can decide who
  /// may read this document with a field comparison. The alternative — a
  /// `get()` on the alert from inside the rule — costs a document read on
  /// every evaluation and counts against the rules engine's access-call
  /// budget, for information the writer already has to hand.
  final String alertOwnerId;

  final String contactId;
  final String contactName;
  final String? responderId;
  final bool seen;
  final bool responding;
  final DateTime? seenAt;
  final DateTime? respondedAt;

  final String? note;

  AlertResponseDto({
    required this.id,
    required this.alertId,
    required this.alertOwnerId,
    required this.contactId,
    required this.contactName,
    this.responderId,
    this.seen = false,
    this.responding = false,
    this.seenAt,
    this.respondedAt,
    this.note,
  });

  factory AlertResponseDto.fromMap(Map<String, dynamic> map) => AlertResponseDto(
    id: map['id'] as String,
    alertId: map['alertId'] as String,
    alertOwnerId: map['alertOwnerId'] as String? ?? '',
    contactId: map['contactId'] as String,
    contactName: map['contactName'] as String,
    responderId: map['responderId'] as String?,
    seen: map['seen'] as bool? ?? false,
    responding: map['responding'] as bool? ?? false,
    seenAt: map['seenAt'] != null ? DateTime.parse(map['seenAt'] as String) : null,
    respondedAt: map['respondedAt'] != null ? DateTime.parse(map['respondedAt'] as String) : null,
    note: map['note'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'alertId': alertId,
    'alertOwnerId': alertOwnerId,
    'contactId': contactId,
    'contactName': contactName,
    'responderId': responderId,
    'seen': seen,
    'responding': responding,
    'seenAt': seenAt?.toIso8601String(),
    'respondedAt': respondedAt?.toIso8601String(),
    'note': note,
  };
}
