import 'dart:async';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/services/firebase_messaging_service.dart';

class TestMessaging extends Fake implements FirebaseMessaging {
  final calls = <String>[];
  bool failDeletion = false;
  Completer<String?>? tokenRequest;
  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async =>
      tokenRequest == null ? 'installation-token' : await tokenRequest!.future;
  @override
  Future<void> setAutoInitEnabled(bool enabled) async {
    calls.add('auto:$enabled');
  }

  @override
  Future<void> deleteToken() async {
    calls.add('delete');
    if (failDeletion) throw StateError('offline');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'profile recovery preserves health data and installed push token',
    () async {
      final db = FakeFirebaseFirestore();
      await db.collection('users').doc('user').set({
        'medicationReminders': [
          {'id': 'r'},
        ],
        'seizureActionPlan': 'Stay with them',
        'emergencyNote': 'Important information',
        'fcmToken': 'active-token',
      });
      await FirestoreService(db).upsertUser(
        UserDto(
          uid: 'user',
          email: 'test@example.com',
          displayName: 'Updated name',
          privacyConsentAt: DateTime.now(),
          privacyConsentVersion: '1',
        ),
        profileSetupOnly: true,
      );
      final saved = (await db.collection('users').doc('user').get()).data()!;
      expect(saved['seizureActionPlan'], 'Stay with them');
      expect(saved['emergencyNote'], 'Important information');
      expect(saved['fcmToken'], 'active-token');
      expect(saved['medicationReminders'], [
        {'id': 'r'},
      ]);
      expect(saved['displayName'], 'Updated name');
    },
  );
  test('push registration cannot create a token-only profile', () async {
    final db = FakeFirebaseFirestore();
    final result = await FirestoreService(
      db,
    ).updateFcmToken('new-user', 'token');
    expect(result.isSuccess, isFalse);
    expect(
      (await db.collection('users').doc('new-user').get()).exists,
      isFalse,
    );
  });
  test('incomplete profiles are identified before entering the app', () async {
    final db = FakeFirebaseFirestore();
    final service = FirestoreService(db);
    await db.collection('users').doc('new-user').set({'fcmToken': 'token'});
    expect(
      (await service.getUser('new-user', requireCompleteProfile: true)).error,
      'Profile incomplete',
    );
    await db.collection('users').doc('new-user').set({
      'uid': 'new-user',
      'email': 'test@example.com',
      'displayName': 'Test',
    });
    expect(
      (await service.getUser('new-user', requireCompleteProfile: true)).error,
      'Profile incomplete',
    );
    await db.collection('users').doc('new-user').update({
      'privacyConsentAt': DateTime.now().toIso8601String(),
      'privacyConsentVersion': '1',
    });
    expect(
      (await service.getUser(
        'new-user',
        requireCompleteProfile: true,
      )).isSuccess,
      isTrue,
    );
  });
  test('sign-out detaches matching token and revokes installation', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('old-user').set({
      'fcmToken': 'installation-token',
    });
    final messaging = TestMessaging();
    final service = FirebaseMessagingService(
      messaging: messaging,
      firestore: FirestoreService(db),
      currentUid: () => 'old-user',
    );
    await service.prepareForSignOut();
    expect(
      (await db.collection('users').doc('old-user').get()).data()!.containsKey(
        'fcmToken',
      ),
      isFalse,
    );
    expect(messaging.calls, ['auto:false', 'delete']);
    expect(service.fcmRegistrationReady.value, isFalse);
  });
  test(
    'detachment preserves a replacement token from another device',
    () async {
      final db = FakeFirebaseFirestore();
      await db.collection('users').doc('old-user').set({
        'fcmToken': 'other-device',
      });
      await FirestoreService(
        db,
      ).detachFcmToken('old-user', 'installation-token');
      expect(
        (await db.collection('users').doc('old-user').get())
            .data()!['fcmToken'],
        'other-device',
      );
    },
  );
  test(
    'sign-out waits for an in-flight token request before revoking it',
    () async {
      final messaging = TestMessaging()..tokenRequest = Completer<String?>();
      final db = FakeFirebaseFirestore();
      await db.collection('users').doc('old-user').set({
        'fcmToken': 'installation-token',
      });
      final service = FirebaseMessagingService(
        messaging: messaging,
        firestore: FirestoreService(db),
        currentUid: () => 'old-user',
      );
      final refresh = service.refreshToken();
      await Future<void>.delayed(Duration.zero);
      final signOut = service.prepareForSignOut();
      await Future<void>.delayed(Duration.zero);
      expect(messaging.calls.contains('delete'), isFalse);
      messaging.tokenRequest!.complete('installation-token');
      await refresh;
      await signOut;
      expect(messaging.calls.last, 'delete');
      expect(
        (await db.collection('users').doc('old-user').get())
            .data()!
            .containsKey('fcmToken'),
        isFalse,
      );
    },
  );
  test('sign-out preparation reports failure when revocation fails', () async {
    final messaging = TestMessaging()..failDeletion = true;
    final service = FirebaseMessagingService(
      messaging: messaging,
      firestore: FirestoreService(FakeFirebaseFirestore()),
      currentUid: () => 'old-user',
    );
    await expectLater(service.prepareForSignOut(), throwsStateError);
  });
}
