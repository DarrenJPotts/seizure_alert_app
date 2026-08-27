import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/dtos/alert_response_dto.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/dtos/heads_up_dto.dart';
import 'package:seizure_app/core/dtos/invite_dto.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/dtos/alert_detail_dto.dart';
import 'package:seizure_app/core/dtos/watched_person_dto.dart';

import '../../support/fixtures.dart';

/// DTO serialisation is the contract between the Flutter client and both
/// Firestore and `functions/index.js`. Nothing enforces it at compile time, so
/// a renamed key or a dropped field fails silently in production — the write
/// succeeds, the field is simply absent, and the Cloud Function that reads it
/// finds undefined. These tests are the enforcement.
void main() {
  group('AlertDto', () {
    test('round-trips every field', () {
      final AlertDto original = Fixtures.alert();
      final AlertDto decoded = AlertDto.fromMap(original.toMap());

      expect(decoded.id, original.id);
      expect(decoded.userId, original.userId);
      expect(decoded.type, original.type);
      expect(decoded.status, original.status);
      expect(decoded.latitude, original.latitude);
      expect(decoded.longitude, original.longitude);
      expect(decoded.locationLabel, original.locationLabel);
      expect(decoded.message, original.message);
      expect(decoded.createdAt, original.createdAt);
      expect(decoded.resolvedAt, original.resolvedAt);
    });

    test('round-trips with every optional field null', () {
      final AlertDto original = AlertDto(
        id: 'a',
        userId: 'u',
        type: AlertType.headsUpExpired,
        status: AlertStatus.cancelled,
        createdAt: Fixtures.at,
      );
      final AlertDto decoded = AlertDto.fromMap(original.toMap());

      expect(decoded.latitude, isNull);
      expect(decoded.longitude, isNull);
      expect(decoded.locationLabel, isNull);
      expect(decoded.message, isNull);
      expect(decoded.resolvedAt, isNull);
    });

    test('serialises enums as the names the Cloud Functions match on', () {
      // functions/index.js switches on these exact strings in getCreatedCopy
      // and getCancelledCopy. Renaming an enum value here silently stops the
      // contact circle being notified.
      for (final (AlertType type, String name) in <(AlertType, String)>[
        (AlertType.sos, 'sos'),
        (AlertType.headsUp, 'headsUp'),
        (AlertType.headsUpExpired, 'headsUpExpired'),
      ]) {
        expect(Fixtures.alert(type: type).toMap()['type'], name);
      }

      for (final (AlertStatus status, String name) in <(AlertStatus, String)>[
        (AlertStatus.sent, 'sent'),
        (AlertStatus.resolved, 'resolved'),
        (AlertStatus.cancelled, 'cancelled'),
      ]) {
        expect(Fixtures.alert(status: status).toMap()['status'], name);
      }
    });

    test('copyWith preserves fields it is not given', () {
      final AlertDto original = Fixtures.alert();
      final AlertDto copy = original.copyWith(status: AlertStatus.resolved);

      expect(copy.status, AlertStatus.resolved);
      expect(copy.id, original.id);
      expect(copy.message, original.message);
      expect(copy.locationLabel, original.locationLabel);
      expect(copy.createdAt, original.createdAt);
    });

    test('copyWith attaches coordinates to an alert that had none', () {
      // This is the SOS flow: the alert is created and sent immediately, then
      // the GPS fix is attached once it resolves.
      final AlertDto original = Fixtures.alert(latitude: null, longitude: null);
      final AlertDto located = original.copyWith(latitude: -26.2041, longitude: 28.0473);

      expect(located.latitude, -26.2041);
      expect(located.longitude, 28.0473);
    });
  });

  group('ContactDto', () {
    test('round-trips every field', () {
      final ContactDto original = Fixtures.contact();
      final ContactDto decoded = ContactDto.fromMap(original.toMap());

      expect(decoded.id, original.id);
      expect(decoded.userId, original.userId);
      expect(decoded.name, original.name);
      expect(decoded.phone, original.phone);
      expect(decoded.relation, original.relation);
      expect(decoded.priority, original.priority);
      expect(decoded.notifyViaSms, original.notifyViaSms);
      expect(decoded.notifyViaPush, original.notifyViaPush);
      expect(decoded.createdAt, original.createdAt);
      expect(decoded.status, original.status);
    });

    test('writes a normalised phone alongside the raw one', () {
      // getPeopleIWatch and getAlertDetail query on phoneNormalized. If toMap
      // stops emitting it, those lookups match nothing and the contact silently
      // receives no alerts.
      final Map<String, dynamic> map = Fixtures.contact(phone: '082 123 4567').toMap();

      expect(map['phone'], '082 123 4567', reason: 'raw value kept for display');
      expect(map['phoneNormalized'], '+27821234567');
    });

    test('emits a null normalised phone when the raw value is unusable', () {
      expect(Fixtures.contact(phone: 'not a number').toMap()['phoneNormalized'], isNull);
    });

    test('defaults an unknown status to active rather than throwing', () {
      // A document written by a future version of the app must not crash this
      // one — it is emergency-contact data.
      final Map<String, dynamic> map = Fixtures.contact().toMap()..['status'] = 'some_future_status';

      expect(ContactDto.fromMap(map).status, ContactStatus.active);
    });

    test('defaults missing notify flags to true', () {
      final Map<String, dynamic> map = Fixtures.contact().toMap()
        ..remove('notifyViaSms')
        ..remove('notifyViaPush');
      final ContactDto decoded = ContactDto.fromMap(map);

      expect(decoded.notifyViaSms, isTrue);
      expect(decoded.notifyViaPush, isTrue);
    });
  });

  group('UserDto', () {
    test('round-trips every field', () {
      final UserDto original = Fixtures.user();
      final UserDto decoded = UserDto.fromMap(original.toMap());

      expect(decoded.uid, original.uid);
      expect(decoded.email, original.email);
      expect(decoded.displayName, original.displayName);
      expect(decoded.photoUrl, original.photoUrl);
      expect(decoded.phone, original.phone);
      expect(decoded.fcmToken, original.fcmToken);
      expect(decoded.bloodType, original.bloodType);
      expect(decoded.seizureType, original.seizureType);
      expect(decoded.medications, original.medications);
      expect(decoded.emergencyNote, original.emergencyNote);
    });

    test('writes a normalised phone alongside the raw one', () {
      final Map<String, dynamic> map = Fixtures.user(phone: '0821234567').toMap();

      expect(map['phone'], '0821234567');
      expect(map['phoneNormalized'], '+27821234567');
    });

    test('copyWith preserves phone and fcmToken when they are not passed', () {
      // upsertUser writes a full toMap() with merge:true, so a copyWith that
      // dropped these would write explicit nulls over good data — merge does
      // not protect against a key that is present and null.
      final UserDto original = Fixtures.user();
      final UserDto copy = original.copyWith(displayName: 'New Name');

      expect(copy.displayName, 'New Name');
      expect(copy.phone, original.phone);
      expect(copy.fcmToken, original.fcmToken);
    });

    test('decodes a medications list written as dynamic', () {
      final Map<String, dynamic> map = Fixtures.user().toMap()
        ..['medications'] = <dynamic>['Lamotrigine', 'Levetiracetam'];

      expect(UserDto.fromMap(map).medications, <String>['Lamotrigine', 'Levetiracetam']);
    });
  });

  group('AlertResponseDto', () {
    test('round-trips every field', () {
      final AlertResponseDto original = Fixtures.alertResponse();
      final AlertResponseDto decoded = AlertResponseDto.fromMap(original.toMap());

      expect(decoded.id, original.id);
      expect(decoded.alertId, original.alertId);
      expect(decoded.alertOwnerId, original.alertOwnerId);
      expect(decoded.contactId, original.contactId);
      expect(decoded.contactName, original.contactName);
      expect(decoded.responderId, original.responderId);
      expect(decoded.seen, original.seen);
      expect(decoded.responding, original.responding);
      expect(decoded.seenAt, original.seenAt);
      expect(decoded.respondedAt, original.respondedAt);
    });

    test('always emits alertOwnerId, which the security rules require', () {
      // firestore.rules grants the patient read access by comparing
      // alertOwnerId to their uid, and rejects creates without it. A response
      // written without this field is unreadable by the person it concerns.
      expect(Fixtures.alertResponse().toMap()['alertOwnerId'], 'user-1');
    });

    test('tolerates a legacy document written before alertOwnerId existed', () {
      final Map<String, dynamic> map = Fixtures.alertResponse().toMap()..remove('alertOwnerId');

      expect(AlertResponseDto.fromMap(map).alertOwnerId, '');
    });

    test('defaults seen and responding to false when absent', () {
      final Map<String, dynamic> map = Fixtures.alertResponse().toMap()
        ..remove('seen')
        ..remove('responding');
      final AlertResponseDto decoded = AlertResponseDto.fromMap(map);

      expect(decoded.seen, isFalse);
      expect(decoded.responding, isFalse);
    });
  });

  group('HeadsUpDto', () {
    test('round-trips every field', () {
      final HeadsUpDto original = Fixtures.headsUp();
      final HeadsUpDto decoded = HeadsUpDto.fromMap(original.toMap());

      expect(decoded.id, original.id);
      expect(decoded.userId, original.userId);
      expect(decoded.createdAt, original.createdAt);
      expect(decoded.expiresAt, original.expiresAt);
      expect(decoded.note, original.note);
      expect(decoded.status, original.status);
    });

    test('emits expiresAtMs as an absolute UTC instant', () {
      // expiresAt serialises via toIso8601String(), which for a local DateTime
      // carries no timezone — the sweep in functions/index.js cannot compare
      // it to its own clock. expiresAtMs is what the sweep actually queries.
      final DateTime expiry = DateTime.utc(2026, 3, 14, 10, 30);
      final Map<String, dynamic> map = Fixtures.headsUp(expiresAt: expiry).toMap();

      expect(map['expiresAtMs'], expiry.millisecondsSinceEpoch);
    });

    test('expiresAtMs is identical for the same instant in any timezone', () {
      final DateTime utc = DateTime.utc(2026, 3, 14, 10, 30);
      final HeadsUpDto fromUtc = Fixtures.headsUp(expiresAt: utc);
      final HeadsUpDto fromLocal = Fixtures.headsUp(expiresAt: utc.toLocal());

      expect(fromLocal.expiresAtMs, fromUtc.expiresAtMs);
    });

    test('isActive is true only while active and before expiry', () {
      final DateTime future = DateTime.now().add(const Duration(minutes: 30));
      final DateTime past = DateTime.now().subtract(const Duration(minutes: 1));

      expect(Fixtures.headsUp(expiresAt: future).isActive, isTrue);
      expect(Fixtures.headsUp(expiresAt: past).isActive, isFalse, reason: 'expired windows are not active');
      expect(
        Fixtures.headsUp(expiresAt: future, status: HeadsUpStatus.checkedIn).isActive,
        isFalse,
        reason: 'a checked-in window is not active even before expiry',
      );
      expect(Fixtures.headsUp(expiresAt: future, status: HeadsUpStatus.cancelled).isActive, isFalse);
    });

    test('remaining counts down and goes negative past expiry', () {
      expect(
        Fixtures.headsUp(expiresAt: DateTime.now().add(const Duration(minutes: 30))).remaining.inMinutes,
        closeTo(30, 1),
      );
      expect(
        Fixtures.headsUp(expiresAt: DateTime.now().subtract(const Duration(minutes: 5))).remaining.isNegative,
        isTrue,
      );
    });

    test('copyWith changes only the status', () {
      final HeadsUpDto original = Fixtures.headsUp();
      final HeadsUpDto copy = original.copyWith(status: HeadsUpStatus.expired);

      expect(copy.status, HeadsUpStatus.expired);
      expect(copy.id, original.id);
      expect(copy.expiresAt, original.expiresAt);
      expect(copy.note, original.note);
    });
  });

  group('SeizureLogDto', () {
    test('round-trips every field', () {
      final SeizureLogDto original = Fixtures.seizureLog();
      final SeizureLogDto decoded = SeizureLogDto.fromMap(original.toMap());

      expect(decoded.id, original.id);
      expect(decoded.userId, original.userId);
      expect(decoded.occurredAt, original.occurredAt);
      expect(decoded.durationSeconds, original.durationSeconds);
      expect(decoded.location, original.location);
      expect(decoded.latitude, original.latitude);
      expect(decoded.longitude, original.longitude);
      expect(decoded.notes, original.notes);
      expect(decoded.trigger, original.trigger);
      expect(decoded.alertFired, original.alertFired);
      expect(decoded.alertId, original.alertId);
    });

    test('decodes an integer coordinate as a double', () {
      // Firestore returns a whole number as int, not double.
      final Map<String, dynamic> map = Fixtures.seizureLog().toMap()
        ..['latitude'] = -33
        ..['longitude'] = 18;
      final SeizureLogDto decoded = SeizureLogDto.fromMap(map);

      expect(decoded.latitude, -33.0);
      expect(decoded.longitude, 18.0);
    });

    test('defaults alertFired to false when absent', () {
      final Map<String, dynamic> map = Fixtures.seizureLog().toMap()..remove('alertFired');

      expect(SeizureLogDto.fromMap(map).alertFired, isFalse);
    });
  });

  group('InviteDto', () {
    test('decodes every field', () {
      final InviteDto decoded = Fixtures.invite();

      expect(decoded.id, 'invite-1');
      expect(decoded.contactId, 'contact-1');
      expect(decoded.senderUid, 'user-1');
      expect(decoded.senderName, 'Darren Potts');
      expect(decoded.recipientUid, 'user-2');
      expect(decoded.recipientPhone, '+27829876543');
      expect(decoded.status, InviteStatus.pending);
      expect(decoded.createdAt, Fixtures.at);
      expect(decoded.respondedAt, isNull);
    });

    test('decodes each status the Cloud Function writes', () {
      for (final (String name, InviteStatus expected) in <(String, InviteStatus)>[
        ('pending', InviteStatus.pending),
        ('accepted', InviteStatus.accepted),
        ('declined', InviteStatus.declined),
      ]) {
        expect(InviteDto.fromMap(Fixtures.inviteMap(status: name)).status, expected);
      }
    });

    test('defaults an unknown status to pending', () {
      expect(InviteDto.fromMap(Fixtures.inviteMap(status: 'weird')).status, InviteStatus.pending);
    });

    test('decodes respondedAt once the invite is answered', () {
      final InviteDto decoded = InviteDto.fromMap(
        Fixtures.inviteMap(status: 'accepted', respondedAt: Fixtures.at.toIso8601String()),
      );

      expect(decoded.respondedAt, Fixtures.at);
    });
  });

  group('WatchedPersonDto', () {
    test('decodes every field', () {
      final WatchedPersonDto decoded = Fixtures.watchedPerson();

      expect(decoded.ownerId, 'user-1');
      expect(decoded.ownerName, 'Darren Potts');
      expect(decoded.ownerPhone, '+27821234567');
      expect(decoded.contactId, 'contact-1');
      expect(decoded.status, WatchedPersonStatus.sos);
      expect(decoded.activeAlertId, 'alert-1');
    });

    test('decodes each status getPeopleIWatch returns', () {
      for (final (String name, WatchedPersonStatus expected) in <(String, WatchedPersonStatus)>[
        ('sos', WatchedPersonStatus.sos),
        ('headsUp', WatchedPersonStatus.headsUp),
        ('monitoring', WatchedPersonStatus.monitoring),
      ]) {
        expect(WatchedPersonDto.fromMap(Fixtures.watchedPersonMap(status: name)).status, expected);
      }
    });

    test('falls back to monitoring for an unknown status', () {
      expect(WatchedPersonDto.fromMap(Fixtures.watchedPersonMap(status: '???')).status, WatchedPersonStatus.monitoring);
    });
  });

  group('AlertDetailDto', () {
    test('decodes the nested payload getAlertDetail returns', () {
      final decoded = Fixtures.alertDetail();

      expect(decoded.alert.id, 'alert-1');
      expect(decoded.alert.type, AlertType.sos);
      expect(decoded.ownerProfile.displayName, 'Darren Potts');
      expect(decoded.ownerProfile.bloodType, 'O+');
      expect(decoded.callerContactId, 'contact-1');
      expect(decoded.callerContactName, 'Jane Potts');
    });

    test('decodes a callable payload whose maps are not typed', () {
      // cloud_functions hands back Map<Object?, Object?> on Android, which is
      // why AlertDetailDto re-wraps every nested map before decoding.
      final Map<String, dynamic> payload = Fixtures.alertDetailMap();
      final Map<String, dynamic> loose = <String, dynamic>{
        ...payload,
        'alert': Map<Object?, Object?>.from(payload['alert'] as Map),
        'ownerProfile': Map<Object?, Object?>.from(payload['ownerProfile'] as Map),
      };

      expect(() => Fixtures.alertDetail(), returnsNormally);
      expect(AlertDetailDto.fromMap(loose).alert.id, 'alert-1');
    });

    test('tolerates an owner profile with no medical details', () {
      final Map<String, dynamic> payload = Fixtures.alertDetailMap();
      payload['ownerProfile'] = <String, dynamic>{
        'displayName': 'Darren Potts',
        'phone': null,
        'bloodType': null,
        'seizureType': null,
        'emergencyNote': null,
      };
      final decoded = AlertDetailDto.fromMap(payload);

      expect(decoded.ownerProfile.displayName, 'Darren Potts');
      expect(decoded.ownerProfile.bloodType, isNull);
    });
  });
}
