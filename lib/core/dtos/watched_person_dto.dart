enum WatchedPersonStatus { sos, headsUp, monitoring }

class WatchedPersonDto {
  final String ownerId;
  final String ownerName;
  final String? ownerPhone;
  final String contactId;
  final WatchedPersonStatus status;
  final String? activeAlertId;

  WatchedPersonDto({
    required this.ownerId,
    required this.ownerName,
    this.ownerPhone,
    required this.contactId,
    required this.status,
    this.activeAlertId,
  });

  factory WatchedPersonDto.fromMap(Map<String, dynamic> map) => WatchedPersonDto(
    ownerId: map['ownerId'] as String,
    ownerName: map['ownerName'] as String,
    ownerPhone: map['ownerPhone'] as String?,
    contactId: map['contactId'] as String,
    status: WatchedPersonStatus.values.firstWhere(
      (e) => e.name == map['status'],
      orElse: () => WatchedPersonStatus.monitoring,
    ),
    activeAlertId: map['activeAlertId'] as String?,
  );
}
