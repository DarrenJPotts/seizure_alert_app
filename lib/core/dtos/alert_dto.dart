enum AlertType { sos, headsUpExpired }
enum AlertStatus { sent, resolved, cancelled }

class AlertDto {
  final String id;
  final String userId;
  final AlertType type;
  final AlertStatus status;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;
  final String? message;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  AlertDto({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    this.latitude,
    this.longitude,
    this.locationLabel,
    this.message,
    required this.createdAt,
    this.resolvedAt,
  });

  factory AlertDto.fromMap(Map<String, dynamic> map) => AlertDto(
    id: map['id'] as String,
    userId: map['userId'] as String,
    type: AlertType.values.firstWhere((e) => e.name == map['type']),
    status: AlertStatus.values.firstWhere((e) => e.name == map['status']),
    latitude: (map['latitude'] as num?)?.toDouble(),
    longitude: (map['longitude'] as num?)?.toDouble(),
    locationLabel: map['locationLabel'] as String?,
    message: map['message'] as String?,
    createdAt: DateTime.parse(map['createdAt'] as String),
    resolvedAt: map['resolvedAt'] != null ? DateTime.parse(map['resolvedAt'] as String) : null,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'status': status.name,
    'latitude': latitude,
    'longitude': longitude,
    'locationLabel': locationLabel,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
  };

  AlertDto copyWith({AlertStatus? status, DateTime? resolvedAt}) => AlertDto(
    id: id,
    userId: userId,
    type: type,
    status: status ?? this.status,
    latitude: latitude,
    longitude: longitude,
    locationLabel: locationLabel,
    message: message,
    createdAt: createdAt,
    resolvedAt: resolvedAt ?? this.resolvedAt,
  );
}