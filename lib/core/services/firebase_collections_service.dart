import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:seizure_app/core/constants/firebase_collection_keys.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/dtos/alert_response_dto.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/dtos/invite_dto.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/dtos/heads_up_dto.dart';

class FirestoreService {
  FirestoreService(this._db);

  static FirestoreService instance() => Get.isRegistered<FirestoreService>()
      ? Get.find<FirestoreService>()
      : Get.put(FirestoreService(FirebaseFirestore.instance));

  final FirebaseFirestore _db;

  // ─── Users ────────────────────────────────────────────────────────────────

  Future<ResultDto<void>> upsertUser(UserDto user) async {
    try {
      await _db.collection(FirebaseCollectionKeys.users).doc(user.uid).set(user.toMap(), SetOptions(merge: true));
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<ResultDto<void>> updateFcmToken(String uid, String token) async {
    try {
      await _db
          .collection(FirebaseCollectionKeys.users)
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<ResultDto<UserDto>> getUser(String uid) async {
    try {
      final doc = await _db.collection(FirebaseCollectionKeys.users).doc(uid).get();
      if (!doc.exists) return ResultDto.failure('User not found');

      return ResultDto.success(UserDto.fromMap(doc.data()!));
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  // ─── Contacts ─────────────────────────────────────────────────────────────

  Stream<List<ContactDto>> watchContacts(String userId) {
    return _db
        .collection(FirebaseCollectionKeys.contacts)
        .where('userId', isEqualTo: userId)
        .orderBy('priority')
        .snapshots()
        .map((s) => s.docs.map((d) => ContactDto.fromMap(d.data())).toList());
  }

  Future<ResultDto<void>> upsertContact(ContactDto contact) async {
    try {
      await _db
          .collection(FirebaseCollectionKeys.contacts)
          .doc(contact.id)
          .set(contact.toMap(), SetOptions(merge: true));
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<ResultDto<void>> deleteContact(String contactId) async {
    try {
      await _db.collection(FirebaseCollectionKeys.contacts).doc(contactId).delete();
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  // ─── Seizure logs ─────────────────────────────────────────────────────────

  Stream<List<SeizureLogDto>> watchSeizureLogs(String userId) {
    return _db
        .collection(FirebaseCollectionKeys.seizureLogs)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => SeizureLogDto.fromMap(d.data())).toList();
          list.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
          return list;
        });
  }

  Future<ResultDto<void>> deleteSeizureLog(String logId) async {
    try {
      await _db.collection(FirebaseCollectionKeys.seizureLogs).doc(logId).delete();
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<ResultDto<void>> addSeizureLog(SeizureLogDto log) async {
    try {
      await _db.collection(FirebaseCollectionKeys.seizureLogs).doc(log.id).set(log.toMap());
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  // ─── Alerts ───────────────────────────────────────────────────────────────

  Future<ResultDto<void>> createAlert(AlertDto alert) async {
    try {
      await _db.collection(FirebaseCollectionKeys.alerts).doc(alert.id).set(alert.toMap());
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<ResultDto<void>> updateAlertStatus(String alertId, AlertStatus status) async {
    try {
      await _db.collection(FirebaseCollectionKeys.alerts).doc(alertId).update({
        'status': status.name,
        'resolvedAt': status == AlertStatus.resolved ? DateTime.now().toIso8601String() : null,
      });
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Stream<List<AlertDto>> watchRecentAlerts(String userId) {
    return _db
        .collection(FirebaseCollectionKeys.alerts)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map((d) => AlertDto.fromMap(d.data())).toList());
  }

  // ─── Heads Up ─────────────────────────────────────────────────────────────

  Future<ResultDto<void>> upsertHeadsUp(HeadsUpDto headsUp) async {
    try {
      await _db.collection(FirebaseCollectionKeys.headsUp).doc(headsUp.id).set(headsUp.toMap());
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<ResultDto<HeadsUpDto?>> getActiveHeadsUp(String userId) async {
    try {
      final snap = await _db
          .collection(FirebaseCollectionKeys.headsUp)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: HeadsUpStatus.active.name)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return ResultDto.success(null);
      return ResultDto.success(HeadsUpDto.fromMap(snap.docs.first.data()));
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  // ─── Account deletion ─────────────────────────────────────────────────────

  // ─── Alert responses ──────────────────────────────────────────────────────

  /// Streams the circle's responses to one of the signed-in user's own alerts.
  /// The `alertOwnerId` filter is not redundant with `alertId`. Firestore
  /// evaluates security rules against the *query* on a list operation, not
  /// against the documents it returns, so it will reject any query it cannot
  /// prove will only match permitted documents. Filtering on `alertId` alone
  /// gives it nothing to match the `alert_responses` read rule against, and
  /// the whole stream is denied.
  Stream<List<AlertResponseDto>> watchAlertResponses(String alertId) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return _db
        .collection(FirebaseCollectionKeys.responses)
        .where('alertId', isEqualTo: alertId)
        .where('alertOwnerId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => AlertResponseDto.fromMap(d.data())).toList());
  }

  // ─── Circle invites ───────────────────────────────────────────────────────
  // Writes (create/accept/decline) only ever happen via the sendCircleInvite
  // / respondToInvite Cloud Functions — these are read-only client methods.

  Future<ResultDto<InviteDto?>> getInvite(String inviteId) async {
    try {
      final doc = await _db.collection(FirebaseCollectionKeys.invites).doc(inviteId).get();
      if (!doc.exists) return ResultDto.success(null);
      return ResultDto.success(InviteDto.fromMap(doc.data()!));
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Stream<List<InviteDto>> watchPendingInvites(String recipientUid) {
    return _db
        .collection(FirebaseCollectionKeys.invites)
        .where('recipientUid', isEqualTo: recipientUid)
        .where('status', isEqualTo: InviteStatus.pending.name)
        .snapshots()
        .map((s) => s.docs.map((d) => InviteDto.fromMap(d.data())).toList());
  }
}
