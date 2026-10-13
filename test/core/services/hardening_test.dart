import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/services/caregiver_service.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/dtos/watched_person_dto.dart';

class UnusedFunctions extends Fake implements FirebaseFunctions {}

void main() {
  test(
    'profile edits and email sync preserve safety plan, consent and token',
    () async {
      final db = FakeFirebaseFirestore();
      final original = <String, dynamic>{
        'uid': 'user',
        'email': 'old@example.com',
        'displayName': 'Old name',
        'seizureActionPlan': 'Stay with them',
        'rescueMedication': 'Recorded dose',
        'medicationReminders': [
          {'id': 'reminder'},
        ],
        'privacyConsentAt': '2026-10-13T10:00:00Z',
        'privacyConsentVersion': '1',
        'fcmToken': 'fresh-token',
      };
      await db.collection('users').doc('user').set(original);
      final service = FirestoreService(db);
      expect(
        (await service.updateProfileFields('user', {
          'displayName': 'New name',
          'phone': null,
          'emergencyNote': null,
        })).isSuccess,
        isTrue,
      );
      expect(
        (await service.updateProfileFields('user', {
          'email': 'new@example.com',
        })).isSuccess,
        isTrue,
      );
      final saved = (await db.collection('users').doc('user').get()).data()!;
      for (final key in [
        'seizureActionPlan',
        'rescueMedication',
        'medicationReminders',
        'privacyConsentAt',
        'privacyConsentVersion',
        'fcmToken',
      ]) {
        expect(saved[key], original[key], reason: key);
      }
      expect(saved['displayName'], 'New name');
      expect(saved['email'], 'new@example.com');
      expect(saved['phone'], isNull);
      expect(saved['emergencyNote'], isNull);
      expect(
        (await service.updateProfileFields('user', {
          'medicationReminders': [],
        })).isSuccess,
        isFalse,
      );
    },
  );
  test('late watch-list requests cannot refill an invalidated cache', () async {
    final pending = Completer<WatchListDto>();
    var calls = 0;
    final service = CaregiverService(
      UnusedFunctions(),
      currentUid: () => 'user',
      loadWatchList: () {
        calls++;
        return calls == 1
            ? pending.future
            : Future.value(WatchListDto(people: [], recentActivity: []));
      },
    );
    final oldRequest = service.getPeopleIWatch();
    service.invalidateWatchList();
    pending.complete(WatchListDto(people: [], recentActivity: []));
    expect((await oldRequest).isSuccess, isFalse);
    expect((await service.getPeopleIWatch()).isSuccess, isTrue);
    expect(calls, 2);
  });
  test('watch-list credentials stay scoped to the signed-in account', () async {
    String? owner = 'A';
    var calls = 0;
    final service = CaregiverService(
      UnusedFunctions(),
      currentUid: () => owner,
      loadWatchList: () async {
        calls++;
        return WatchListDto(people: [], recentActivity: []);
      },
    );
    await service.getPeopleIWatch();
    await service.getPeopleIWatch();
    expect(calls, 1);
    owner = 'B';
    await service.getPeopleIWatch();
    expect(calls, 2);
    owner = null;
    expect((await service.getPeopleIWatch()).isSuccess, isFalse);
  });
}
