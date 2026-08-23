import 'package:seizure_app/core/dtos/alert_dto.dart';

class OwnerProfileDto {
  final String displayName;
  final String? phone;
  final String? bloodType;
  final String? seizureType;
  final String? emergencyNote;

  OwnerProfileDto({
    required this.displayName,
    this.phone,
    this.bloodType,
    this.seizureType,
    this.emergencyNote,
  });

  factory OwnerProfileDto.fromMap(Map<String, dynamic> map) => OwnerProfileDto(
    displayName: map['displayName'] as String,
    phone: map['phone'] as String?,
    bloodType: map['bloodType'] as String?,
    seizureType: map['seizureType'] as String?,
    emergencyNote: map['emergencyNote'] as String?,
  );
}

class AlertDetailDto {
  final AlertDto alert;
  final OwnerProfileDto ownerProfile;
  final String callerContactId;
  final String callerContactName;

  AlertDetailDto({
    required this.alert,
    required this.ownerProfile,
    required this.callerContactId,
    required this.callerContactName,
  });

  factory AlertDetailDto.fromMap(Map<String, dynamic> map) => AlertDetailDto(
    alert: AlertDto.fromMap(_asStringMap(map['alert'])),
    ownerProfile: OwnerProfileDto.fromMap(_asStringMap(map['ownerProfile'])),
    callerContactId: map['callerContactId'] as String,
    callerContactName: map['callerContactName'] as String,
  );
}

Map<String, dynamic> _asStringMap(dynamic value) => Map<String, dynamic>.from(value as Map);
