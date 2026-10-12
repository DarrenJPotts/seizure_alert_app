class WearableDeviceDto {
  const WearableDeviceDto({
    required this.id,
    required this.userId,
    required this.platform,
    required this.name,
    required this.pairedAt,
    this.lastSeenAt,
    this.batteryPercent,
  });

  final String id;
  final String userId;
  final String platform;
  final String name;
  final DateTime pairedAt;
  final DateTime? lastSeenAt;
  final int? batteryPercent;

  bool get recentlySeen =>
      lastSeenAt != null &&
      DateTime.now().difference(lastSeenAt!).inMinutes < 15;

  factory WearableDeviceDto.fromMap(Map<String, dynamic> map) =>
      WearableDeviceDto(
        id: map['id'] as String,
        userId: map['userId'] as String,
        platform: map['platform'] as String? ?? 'wearable',
        name: map['name'] as String? ?? 'Wearable',
        pairedAt:
            DateTime.tryParse(map['pairedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        lastSeenAt: map['lastSeenAtMs'] is num
            ? DateTime.fromMillisecondsSinceEpoch(
                (map['lastSeenAtMs'] as num).toInt(),
              )
            : null,
        batteryPercent: (map['batteryPercent'] as num?)?.toInt(),
      );
}
