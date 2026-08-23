enum InviteStatus { pending, accepted, declined }

class InviteDto {
  final String id;
  final String contactId;
  final String senderUid;
  final String senderName;
  final String recipientUid;
  final String recipientPhone;
  final InviteStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  InviteDto({
    required this.id,
    required this.contactId,
    required this.senderUid,
    required this.senderName,
    required this.recipientUid,
    required this.recipientPhone,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory InviteDto.fromMap(Map<String, dynamic> map) => InviteDto(
    id: map['id'] as String,
    contactId: map['contactId'] as String,
    senderUid: map['senderUid'] as String,
    senderName: map['senderName'] as String,
    recipientUid: map['recipientUid'] as String,
    recipientPhone: map['recipientPhone'] as String,
    status: InviteStatus.values.firstWhere(
      (InviteStatus e) => e.name == map['status'],
      orElse: () => InviteStatus.pending,
    ),
    createdAt: DateTime.parse(map['createdAt'] as String),
    respondedAt: map['respondedAt'] != null
        ? DateTime.parse(map['respondedAt'] as String)
        : null,
  );
}
