import 'package:seizure_app/core/dtos/alert_detail_dto.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/dtos/alert_response_dto.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/dtos/heads_up_dto.dart';
import 'package:seizure_app/core/dtos/invite_dto.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/dtos/watched_person_dto.dart';

/// Builders for fully-populated DTOs.
///
/// Every field is set to a distinct non-default value on purpose. A fixture
/// that leaves optional fields null cannot catch a serialisation bug in those
/// fields, and null-vs-absent is exactly where Firestore round-trips break.
/// Tests that care about the null case override explicitly.
abstract class Fixtures {
  static final DateTime at = DateTime.utc(2026, 3, 14, 9, 30, 15);

  static UserDto user({String uid = 'user-1', String? phone = '+27821234567'}) => UserDto(
    uid: uid,
    email: 'darren@example.com',
    displayName: 'Darren Potts',
    photoUrl: 'https://example.com/a.png',
    phone: phone,
    fcmToken: 'fcm-token-abc',
    bloodType: 'O+',
    seizureType: 'Tonic-clonic',
    medications: const <String>['Lamotrigine', 'Levetiracetam'],
    emergencyNote: 'Do not restrain. Time the seizure.',
  );

  static ContactDto contact({
    String id = 'contact-1',
    String phone = '082 123 4567',
    ContactStatus status = ContactStatus.active,
    bool notifyViaPush = true,
  }) => ContactDto(
    id: id,
    userId: 'user-1',
    name: 'Jane Potts',
    phone: phone,
    relation: 'Sister',
    priority: 2,
    notifyViaSms: true,
    notifyViaPush: notifyViaPush,
    createdAt: at,
    status: status,
  );

  static AlertDto alert({
    String id = 'alert-1',
    AlertType type = AlertType.sos,
    AlertStatus status = AlertStatus.sent,
    double? latitude = -33.9249,
    double? longitude = 18.4241,
  }) => AlertDto(
    id: id,
    userId: 'user-1',
    type: type,
    status: status,
    latitude: latitude,
    longitude: longitude,
    locationLabel: 'Cape Town',
    message: 'Feeling an aura.',
    createdAt: at,
    resolvedAt: at.add(const Duration(minutes: 12)),
  );

  static AlertResponseDto alertResponse({
    String id = 'alert-1_contact-1',
    String alertOwnerId = 'user-1',
    bool seen = true,
    bool responding = true,
  }) => AlertResponseDto(
    id: id,
    alertId: 'alert-1',
    alertOwnerId: alertOwnerId,
    contactId: 'contact-1',
    contactName: 'Jane Potts',
    responderId: 'user-2',
    seen: seen,
    responding: responding,
    seenAt: at,
    respondedAt: at.add(const Duration(minutes: 1)),
  );

  static HeadsUpDto headsUp({
    String id = 'headsup-1',
    HeadsUpStatus status = HeadsUpStatus.active,
    DateTime? expiresAt,
  }) => HeadsUpDto(
    id: id,
    userId: 'user-1',
    createdAt: at,
    expiresAt: expiresAt ?? at.add(const Duration(minutes: 60)),
    note: 'Home alone until 3pm.',
    status: status,
  );

  static SeizureLogDto seizureLog({String id = 'log-1', DateTime? occurredAt}) => SeizureLogDto(
    id: id,
    userId: 'user-1',
    occurredAt: occurredAt ?? at,
    durationSeconds: 95,
    location: 'Kitchen',
    latitude: -33.9249,
    longitude: 18.4241,
    notes: 'Bit tongue.',
    trigger: 'Missed dose',
    alertFired: true,
    alertId: 'alert-1',
  );

  static Map<String, dynamic> inviteMap({String status = 'pending', String? respondedAt}) => <String, dynamic>{
    'id': 'invite-1',
    'contactId': 'contact-1',
    'senderUid': 'user-1',
    'senderName': 'Darren Potts',
    'recipientUid': 'user-2',
    'recipientPhone': '+27829876543',
    'status': status,
    'createdAt': at.toIso8601String(),
    'respondedAt': respondedAt,
  };

  static Map<String, dynamic> watchedPersonMap({String status = 'sos'}) => <String, dynamic>{
    'ownerId': 'user-1',
    'ownerName': 'Darren Potts',
    'ownerPhone': '+27821234567',
    'contactId': 'contact-1',
    'status': status,
    'activeAlertId': 'alert-1',
    'headsUpNote': 'Feeling off, going to lie down.',
    'headsUpAt': '2026-03-14T14:20:00.000',
    'lastSeizureAt': '2026-02-24T09:00:00.000',
    'daysSinceLastSeizure': 18,
    'lastAlertAt': '2026-03-14T14:20:00.000',
  };

  /// The full `getPeopleIWatch` payload — people plus the merged activity
  /// feed the callable builds across all of them.
  static Map<String, dynamic> watchListMap() => <String, dynamic>{
    'people': <Map<String, dynamic>>[watchedPersonMap()],
    'recentActivity': <Map<String, dynamic>>[
      <String, dynamic>{'personName': 'Darren Potts', 'kind': 'headsUp', 'at': '2026-03-14T14:20:00.000'},
      <String, dynamic>{'personName': 'Darren Potts', 'kind': 'sos', 'at': '2026-03-14T08:00:00.000'},
    ],
  };

  static Map<String, dynamic> alertDetailMap() => <String, dynamic>{
    'alert': alert().toMap(),
    'ownerProfile': <String, dynamic>{
      'displayName': 'Darren Potts',
      'phone': '+27821234567',
      'bloodType': 'O+',
      'seizureType': 'Tonic-clonic',
      'emergencyNote': 'Do not restrain.',
      'medications': <String>['Midazolam', 'Lamotrigine'],
      'daysSinceLastSeizure': 18,
    },
    'callerContactId': 'contact-1',
    'callerContactName': 'Jane Potts',
    'notifiedCount': 3,
    'responders': <Map<String, dynamic>>[
      <String, dynamic>{
        'contactId': 'contact-1',
        'contactName': 'Jane Potts',
        'responderId': 'caregiver-1',
        'isCaller': true,
        'seen': true,
        'responding': true,
        'seenAt': '2026-03-14T14:22:00.000',
        'respondedAt': '2026-03-14T14:23:00.000',
      },
      <String, dynamic>{
        'contactId': 'contact-2',
        'contactName': 'Sipho Vilakazi',
        'responderId': 'caregiver-2',
        'isCaller': false,
        'seen': true,
        'responding': false,
        'seenAt': '2026-03-14T14:24:00.000',
      },
    ],
  };

  /// A [WatchedPersonDto] built through its only constructor path.
  static WatchedPersonDto watchedPerson() => WatchedPersonDto.fromMap(watchedPersonMap());

  static InviteDto invite() => InviteDto.fromMap(inviteMap());

  static AlertDetailDto alertDetail() => AlertDetailDto.fromMap(alertDetailMap());

  static WatchListDto watchList() => WatchListDto.fromMap(watchListMap());
}
