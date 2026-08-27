import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/dtos/watched_person_dto.dart' show parseTimestamp;

class OwnerProfileDto {
  final String displayName;
  final String? phone;
  final String? bloodType;
  final String? seizureType;
  final String? emergencyNote;

  final List<String> medications;

  final int? daysSinceLastSeizure;

  OwnerProfileDto({
    required this.displayName,
    this.phone,
    this.bloodType,
    this.seizureType,
    this.emergencyNote,
    this.medications = const <String>[],
    this.daysSinceLastSeizure,
  });

  List<String> get carePlanSteps {
    final String? note = emergencyNote;
    if (note == null || note.trim().isEmpty) return const <String>[];
    return note
        .split(RegExp(r'[\r\n]+'))
        .map((String line) => line.replaceFirst(RegExp(r'^\s*(?:\d+[.)]|[-*•])\s*'), '').trim())
        .where((String line) => line.isNotEmpty)
        .toList();
  }

  factory OwnerProfileDto.fromMap(Map<String, dynamic> map) => OwnerProfileDto(
    displayName: map['displayName'] as String,
    phone: map['phone'] as String?,
    bloodType: map['bloodType'] as String?,
    seizureType: map['seizureType'] as String?,
    emergencyNote: map['emergencyNote'] as String?,
    medications: (map['medications'] as List? ?? <dynamic>[]).map((e) => e.toString()).toList(),
    daysSinceLastSeizure: (map['daysSinceLastSeizure'] as num?)?.toInt(),
  );
}

class AlertResponderDto {
  final String? contactId;
  final String contactName;
  final String? responderId;

  final bool isCaller;

  final bool seen;
  final bool responding;
  final DateTime? seenAt;
  final DateTime? respondedAt;
  final String? note;

  AlertResponderDto({
    this.contactId,
    required this.contactName,
    this.responderId,
    this.isCaller = false,
    this.seen = false,
    this.responding = false,
    this.seenAt,
    this.respondedAt,
    this.note,
  });

  factory AlertResponderDto.fromMap(Map<String, dynamic> map) => AlertResponderDto(
    contactId: map['contactId'] as String?,
    contactName: map['contactName'] as String? ?? 'Someone',
    responderId: map['responderId'] as String?,
    isCaller: map['isCaller'] as bool? ?? false,
    seen: map['seen'] as bool? ?? false,
    responding: map['responding'] as bool? ?? false,
    seenAt: parseTimestamp(map['seenAt']),
    respondedAt: parseTimestamp(map['respondedAt']),
    note: map['note'] as String?,
  );
}

class AlertDetailDto {
  final AlertDto alert;
  final OwnerProfileDto ownerProfile;
  final String callerContactId;
  final String callerContactName;

  final int notifiedCount;

  final List<AlertResponderDto> responders;

  AlertDetailDto({
    required this.alert,
    required this.ownerProfile,
    required this.callerContactId,
    required this.callerContactName,
    this.notifiedCount = 0,
    this.responders = const <AlertResponderDto>[],
  });

  AlertResponderDto? get callerResponse {
    for (final AlertResponderDto responder in responders) {
      if (responder.isCaller) return responder;
    }
    return null;
  }

  List<AlertResponderDto> get otherResponders => responders.where((AlertResponderDto r) => !r.isCaller).toList();

  factory AlertDetailDto.fromMap(Map<String, dynamic> map) => AlertDetailDto(
    alert: AlertDto.fromMap(_asStringMap(map['alert'])),
    ownerProfile: OwnerProfileDto.fromMap(_asStringMap(map['ownerProfile'])),
    callerContactId: map['callerContactId'] as String,
    callerContactName: map['callerContactName'] as String,
    notifiedCount: (map['notifiedCount'] as num?)?.toInt() ?? 0,
    responders: (map['responders'] as List? ?? <dynamic>[])
        .map((e) => AlertResponderDto.fromMap(_asStringMap(e)))
        .toList(),
  );
}

Map<String, dynamic> _asStringMap(dynamic value) => Map<String, dynamic>.from(value as Map);
