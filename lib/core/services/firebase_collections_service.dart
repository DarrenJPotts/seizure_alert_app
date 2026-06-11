import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:seizure_app/core/constants/firebase_collection_keys.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/dtos/alert_response_dto.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/features/heads_up/models/heads_up_dto.dart';

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
      await _db.collection(FirebaseCollectionKeys.contacts).doc(contact.id).set(contact.toMap());
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

  Future<void> deleteAllUserData(String uid) async {
    await Future.wait([
      _deleteWhere(FirebaseCollectionKeys.contacts, uid),
      _deleteWhere(FirebaseCollectionKeys.seizureLogs, uid),
      _deleteWhere(FirebaseCollectionKeys.alerts, uid),
      _deleteWhere(FirebaseCollectionKeys.headsUp, uid),
    ]);
    await _db.collection(FirebaseCollectionKeys.users).doc(uid).delete();
  }

  Future<void> _deleteWhere(String collection, String uid) async {
    final snap = await _db
        .collection(collection)
        .where('userId', isEqualTo: uid)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  // ─── Alert responses ──────────────────────────────────────────────────────

  Stream<List<AlertResponseDto>> watchAlertResponses(String alertId) {
    return _db
        .collection(FirebaseCollectionKeys.responses)
        .where('alertId', isEqualTo: alertId)
        .snapshots()
        .map((s) => s.docs.map((d) => AlertResponseDto.fromMap(d.data())).toList());
  }

  Future<ResultDto<void>> upsertAlertResponse(AlertResponseDto response) async {
    try {
      await _db
          .collection(FirebaseCollectionKeys.responses)
          .doc(response.id)
          .set(response.toMap(), SetOptions(merge: true));
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }
}
