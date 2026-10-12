class AlertDeliveryDto {
  const AlertDeliveryDto({
    required this.alertId,
    required this.contactId,
    required this.status,
    this.escalationStage = 0,
  });

  final String alertId;
  final String contactId;
  final String status;
  final int escalationStage;

  factory AlertDeliveryDto.fromMap(Map<String, dynamic> map) =>
      AlertDeliveryDto(
        alertId: map['alertId'] as String,
        contactId: map['contactId'] as String,
        status: map['status'] as String? ?? 'pending',
        escalationStage: (map['escalationStage'] as num?)?.toInt() ?? 0,
      );
}
