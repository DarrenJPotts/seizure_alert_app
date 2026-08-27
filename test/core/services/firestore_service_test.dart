import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/dtos/heads_up_dto.dart';
import 'package:seizure_app/core/dtos/invite_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';

import '../../support/fixtures.dart';

/// Exercises the read/write layer against an in-memory Firestore.
///
/// `watchAlertResponses` is excluded: the service takes its Firestore instance
/// by injection but reads `FirebaseAuth.instance` statically, so that one path
/// needs a live Firebase app. Everything else here is reachable.
void main() {
  late FakeFirebaseFirestore db;
  late FirestoreService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = FirestoreService(db);
  });

  group('users', () {
    test('upsertUser writes the document under the uid', () async {
      final ResultDto<void> result = await service.upsertUser(Fixtures.user());

      expect(result.isSuccess, isTrue);
      final snap = await db.collection('users').doc('user-1').get();
      expect(snap.exists, isTrue);
      expect(snap.data()!['displayName'], 'Darren Potts');
    });

    test('upsertUser stores the normalised phone the functions look up', () async {
      await service.upsertUser(Fixtures.user(phone: '082 123 4567'));

      final snap = await db.collection('users').doc('user-1').get();
      expect(snap.data()!['phoneNormalized'], '+27821234567');
    });

    test('getUser returns the stored user', () async {
      await service.upsertUser(Fixtures.user());

      final ResultDto<UserDto> result = await service.getUser('user-1');

      expect(result.isSuccess, isTrue);
      expect(result.data?.uid, 'user-1');
      expect(result.data?.medications, hasLength(2));
    });

    test('getUser fails for an unknown uid', () async {
      final ResultDto<UserDto> result = await service.getUser('nobody');

      expect(result.isSuccess, isFalse);
      expect(result.error, 'User not found');
      expect(result.data, isNull);
    });

    test('upsertUser merges rather than replacing', () async {
      await service.upsertUser(Fixtures.user());
      await service.upsertUser(Fixtures.user().copyWith(displayName: 'Renamed'));

      final ResultDto<UserDto> result = await service.getUser('user-1');

      expect(result.data?.displayName, 'Renamed');
      expect(result.data?.fcmToken, 'fcm-token-abc');
    });

    test('updateFcmToken touches only the token', () async {
      await service.upsertUser(Fixtures.user());

      await service.updateFcmToken('user-1', 'fresh-token');

      final ResultDto<UserDto> result = await service.getUser('user-1');
      expect(result.data?.fcmToken, 'fresh-token');
      expect(result.data?.displayName, 'Darren Potts', reason: 'a merge write must not clear the rest of the profile');
      expect(result.data?.phone, '+27821234567');
    });
  });

  group('contacts', () {
    test('upsertContact writes and watchContacts reads it back', () async {
      await service.upsertContact(Fixtures.contact());

      final List<ContactDto> emitted = await service.watchContacts('user-1').first;

      expect(emitted, hasLength(1));
      expect(emitted.first.name, 'Jane Potts');
    });

    test('watchContacts excludes other users', () async {
      await service.upsertContact(Fixtures.contact(id: 'mine'));
      await db
          .collection('contacts')
          .doc('theirs')
          .set(Fixtures.contact(id: 'theirs').toMap()..['userId'] = 'other-user');

      final List<ContactDto> emitted = await service.watchContacts('user-1').first;

      expect(emitted, hasLength(1));
      expect(emitted.first.id, 'mine');
    });

    test('watchContacts surfaces pending contacts too', () async {
      // The UI needs to show a pending invite; it is the Cloud Functions that
      // skip pending contacts when notifying, not this query.
      await service.upsertContact(Fixtures.contact(status: ContactStatus.pending));

      final List<ContactDto> emitted = await service.watchContacts('user-1').first;

      expect(emitted.first.status, ContactStatus.pending);
    });

    test('deleteContact removes the document', () async {
      await service.upsertContact(Fixtures.contact());

      await service.deleteContact('contact-1');

      expect(await service.watchContacts('user-1').first, isEmpty);
    });
  });

  group('alerts', () {
    test('createAlert writes under the alert id', () async {
      await service.createAlert(Fixtures.alert());

      final snap = await db.collection('alerts').doc('alert-1').get();
      expect(snap.data()!['type'], 'sos');
      expect(snap.data()!['status'], 'sent');
    });

    test('updateAlertStatus changes status and leaves the rest alone', () async {
      await service.createAlert(Fixtures.alert());

      await service.updateAlertStatus('alert-1', AlertStatus.cancelled);

      final snap = await db.collection('alerts').doc('alert-1').get();
      expect(snap.data()!['status'], 'cancelled');
      expect(snap.data()!['message'], 'Feeling an aura.');
      expect(snap.data()!['latitude'], -33.9249);
    });

    test('createAlert on an existing id attaches a late GPS fix', () async {
      // The SOS flow writes twice: once immediately so contacts are notified
      // without waiting on GPS, then again once the fix resolves.
      final AlertDto initial = Fixtures.alert(latitude: null, longitude: null);
      await service.createAlert(initial);
      await service.createAlert(initial.copyWith(latitude: -26.2041, longitude: 28.0473));

      final snap = await db.collection('alerts').doc('alert-1').get();
      expect(snap.data()!['latitude'], -26.2041);
      expect(snap.data()!['longitude'], 28.0473);
    });

    test('watchRecentAlerts returns newest first', () async {
      final DateTime base = DateTime.utc(2026, 1, 1);
      await service.createAlert(Fixtures.alert(id: 'old'));
      await db.collection('alerts').doc('old').update(<String, Object?>{'createdAt': base.toIso8601String()});
      await service.createAlert(Fixtures.alert(id: 'new'));
      await db.collection('alerts').doc('new').update(<String, Object?>{
        'createdAt': base.add(const Duration(days: 5)).toIso8601String(),
      });

      final List<AlertDto> emitted = await service.watchRecentAlerts('user-1').first;

      expect(emitted.map((AlertDto a) => a.id), <String>['new', 'old']);
    });

    test('watchRecentAlerts caps the history at 20', () async {
      for (int i = 0; i < 25; i++) {
        await service.createAlert(Fixtures.alert(id: 'alert-$i'));
        await db.collection('alerts').doc('alert-$i').update(<String, Object?>{
          'createdAt': DateTime.utc(2026, 1, 1).add(Duration(days: i)).toIso8601String(),
        });
      }

      expect(await service.watchRecentAlerts('user-1').first, hasLength(20));
    });
  });

  group('heads up', () {
    test('upsertHeadsUp writes the field the expiry sweep queries', () async {
      // expireHeadsUpWindows filters on expiresAtMs. A document missing that
      // field is invisible to a range query and would never escalate.
      final DateTime expiry = DateTime.utc(2026, 3, 14, 10, 30);
      await service.upsertHeadsUp(Fixtures.headsUp(expiresAt: expiry));

      final snap = await db.collection('headsUp').doc('headsup-1').get();
      expect(snap.data()!['expiresAtMs'], expiry.millisecondsSinceEpoch);
      expect(snap.data()!['status'], 'active');
    });

    test('getActiveHeadsUp finds an active window', () async {
      await service.upsertHeadsUp(Fixtures.headsUp());

      final ResultDto<HeadsUpDto?> result = await service.getActiveHeadsUp('user-1');

      expect(result.isSuccess, isTrue);
      expect(result.data?.id, 'headsup-1');
    });

    test('getActiveHeadsUp succeeds with null for a checked-in window', () async {
      await service.upsertHeadsUp(Fixtures.headsUp(status: HeadsUpStatus.checkedIn));

      final ResultDto<HeadsUpDto?> result = await service.getActiveHeadsUp('user-1');

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('getActiveHeadsUp ignores another user\'s active window', () async {
      await db
          .collection('headsUp')
          .doc('theirs')
          .set(Fixtures.headsUp(id: 'theirs').toMap()..['userId'] = 'other-user');

      final ResultDto<HeadsUpDto?> result = await service.getActiveHeadsUp('user-1');

      expect(result.data, isNull);
    });

    test('upsertHeadsUp overwrites the status on the same id', () async {
      await service.upsertHeadsUp(Fixtures.headsUp());
      await service.upsertHeadsUp(Fixtures.headsUp().copyWith(status: HeadsUpStatus.cancelled));

      final snap = await db.collection('headsUp').doc('headsup-1').get();
      expect(snap.data()!['status'], 'cancelled');
    });
  });

  group('seizure logs', () {
    test('addSeizureLog writes the entry', () async {
      await service.addSeizureLog(Fixtures.seizureLog());

      final snap = await db.collection('seizureLogs').doc('log-1').get();
      expect(snap.data()!['trigger'], 'Missed dose');
      expect(snap.data()!['durationSeconds'], 95);
    });

    test('watchSeizureLogs emits newest first', () async {
      // HomeViewModel.daysSinceLastSeizure reads index 0 and assumes it is the
      // most recent entry.
      final DateTime base = DateTime.utc(2026, 1, 1);
      await service.addSeizureLog(Fixtures.seizureLog(id: 'old', occurredAt: base));
      await service.addSeizureLog(Fixtures.seizureLog(id: 'new', occurredAt: base.add(const Duration(days: 10))));

      final List<SeizureLogDto> emitted = await service.watchSeizureLogs('user-1').first;

      expect(emitted.map((SeizureLogDto l) => l.id), <String>['new', 'old']);
    });

    test('watchSeizureLogs excludes other users', () async {
      await service.addSeizureLog(Fixtures.seizureLog(id: 'mine'));
      await db
          .collection('seizureLogs')
          .doc('theirs')
          .set(Fixtures.seizureLog(id: 'theirs').toMap()..['userId'] = 'other-user');

      final List<SeizureLogDto> emitted = await service.watchSeizureLogs('user-1').first;

      expect(emitted, hasLength(1));
      expect(emitted.first.id, 'mine');
    });
  });

  group('invites', () {
    Future<void> writeInvite(String id, String status, {String recipient = 'user-2'}) async {
      await db
          .collection('invites')
          .doc(id)
          .set(
            Fixtures.inviteMap(status: status)
              ..['id'] = id
              ..['recipientUid'] = recipient,
          );
    }

    test('getInvite returns the stored invite', () async {
      await writeInvite('invite-1', 'pending');

      final ResultDto<InviteDto?> result = await service.getInvite('invite-1');

      expect(result.isSuccess, isTrue);
      expect(result.data?.senderName, 'Darren Potts');
      expect(result.data?.status, InviteStatus.pending);
    });

    test('getInvite succeeds with null when the invite is gone', () async {
      final ResultDto<InviteDto?> result = await service.getInvite('missing');

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('watchPendingInvites returns only pending ones for the recipient', () async {
      await writeInvite('pending-1', 'pending');
      await writeInvite('accepted-1', 'accepted');
      await writeInvite('declined-1', 'declined');
      await writeInvite('someone-else', 'pending', recipient: 'user-9');

      final List<InviteDto> emitted = await service.watchPendingInvites('user-2').first;

      expect(emitted, hasLength(1));
      expect(emitted.first.id, 'pending-1');
    });
  });

  // `deleteAllUserData` was removed. The two tests that lived here proved it
  // cleared the user document and everything matching `userId == uid` — which
  // was exactly its problem: records that identify a user by another field
  // (`alert_responses` via responderId / alertOwnerId, `invites` via
  // senderUid / recipientUid, `rate_limits` by document id) were never
  // touched, and a client cannot even query them under `firestore.rules`.
  //
  // Erasure now runs in the `deleteMyData` Cloud Function under the Admin SDK.
  // **That path has no automated coverage**: it is a callable, so
  // fake_cloud_firestore cannot exercise it and neither can this suite. It
  // needs an emulator test asserting that all five collections are cleared and
  // that another user's contact rows survive with only `linkedUid` removed.
  // Listed in test/README.md alongside the rules gap.
}
