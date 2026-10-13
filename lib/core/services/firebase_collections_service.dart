import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:seizure_app/core/constants/firebase_collection_keys.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/dtos/alert_response_dto.dart';
import 'package:seizure_app/core/dtos/alert_delivery_dto.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/helpers/phone_number.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/dtos/heads_up_dto.dart';

class FirestoreService {
  FirestoreService(this._db);

  static FirestoreService instance() => Get.isRegistered<FirestoreService>()
      ? Get.find<FirestoreService>()
      : Get.put(FirestoreService(FirebaseFirestore.instance));

  final FirebaseFirestore _db;

  String newDocumentId(String collection) =>
      _db.collection(collection).doc().id;

  Future<ResultDto<void>> upsertUser(
    UserDto user, {
    bool profileSetupOnly = false,
  }) async {
    final String? phoneError = PhoneNumber.validationError(user.phone);
    if (phoneError != null) return ResultDto.failure(phoneError);
    try {
      final values = user.toMap();
      if (profileSetupOnly) {
        const setupFields = {
          'uid',
          'email',
          'displayName',
          'phone',
          'phoneNormalized',
          'privacyConsentAt',
          'privacyConsentVersion',
        };
        values.removeWhere((key, _) => !setupFields.contains(key));
      }
      await _db
          .collection(FirebaseCollectionKeys.users)
          .doc(user.uid)
          .set(values, SetOptions(merge: true));
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<ResultDto<void>> updateProfileFields(
    String uid,
    Map<String, dynamic> fields,
  ) async {
    const editable = {
      'displayName',
      'phone',
      'phoneNormalized',
      'bloodType',
      'seizureType',
      'medications',
      'emergencyNote',
      'email',
    };
    if (fields.keys.any((key) => !editable.contains(key))) {
      return ResultDto.failure('Invalid profile field');
    }
    if (fields.containsKey('phone')) {
      final phone = fields['phone'] as String?;
      final error = PhoneNumber.validationError(phone);
      if (error != null) return ResultDto.failure(error);
      fields = {...fields, 'phoneNormalized': PhoneNumber.normalize(phone)};
    }
    try {
      await _db
          .collection(FirebaseCollectionKeys.users)
          .doc(uid)
          .update(fields);
      return ResultDto.success(null);
    } catch (_) {
      return ResultDto.failure(
        'Your profile could not be saved. Please try again.',
      );
    }
  }

  Future<ResultDto<void>> updateFcmToken(String uid, String token) async {
    try {
      await _db.collection(FirebaseCollectionKeys.users).doc(uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<void> detachFcmToken(String uid, String? token) async {
    final ref = _db.collection(FirebaseCollectionKeys.users).doc(uid);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.exists &&
          token != null &&
          snapshot.data()?['fcmToken'] == token) {
        transaction.update(ref, {
          'fcmToken': FieldValue.delete(),
          'fcmTokenUpdatedAt': FieldValue.delete(),
        });
      }
    });
  }

  Future<ResultDto<void>> updateSafetyPlan(
    String uid,
    Map<String, dynamic> values,
  ) async {
    try {
      await _db
          .collection(FirebaseCollectionKeys.users)
          .doc(uid)
          .set(values, SetOptions(merge: true));
      return ResultDto.success(null);
    } catch (error) {
      return ResultDto.failure(error.toString());
    }
  }

  Future<ResultDto<UserDto>> getUser(
    String uid, {
    bool requireCompleteProfile = false,
  }) async {
    try {
      final doc = await _db
          .collection(FirebaseCollectionKeys.users)
          .doc(uid)
          .get();
      if (!doc.exists) return ResultDto.failure('User not found');

      final data = doc.data()!;
      if (data['uid'] != uid ||
          data['email'] is! String ||
          (requireCompleteProfile &&
              (data['displayName'] is! String ||
                  (data['displayName'] as String).trim().isEmpty ||
                  data['privacyConsentAt'] == null ||
                  data['privacyConsentVersion'] == null))) {
        return ResultDto.failure('Profile incomplete');
      }
      return ResultDto.success(UserDto.fromMap(data));
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Stream<List<ContactDto>> watchContacts(String userId) {
    return _db
        .collection(FirebaseCollectionKeys.contacts)
        .where('userId', isEqualTo: userId)
        .orderBy('priority')
        .snapshots()
        .map((s) => s.docs.map((d) => ContactDto.fromMap(d.data())).toList());
  }

  Future<ResultDto<void>> upsertContact(ContactDto contact) async {
    final String? phoneError = PhoneNumber.validationError(
      contact.phone,
      required: true,
    );
    if (phoneError != null) return ResultDto.failure(phoneError);
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
      await _db
          .collection(FirebaseCollectionKeys.contacts)
          .doc(contactId)
          .delete();
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Stream<List<SeizureLogDto>> watchSeizureLogs(String userId) {
    return _db
        .collection(FirebaseCollectionKeys.seizureLogs)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => SeizureLogDto.fromMap(d.data()))
              .toList();
          list.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
          return list;
        });
  }

  Future<ResultDto<void>> deleteSeizureLog(String logId) async {
    try {
      await _db
          .collection(FirebaseCollectionKeys.seizureLogs)
          .doc(logId)
          .delete();
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<ResultDto<void>> addSeizureLog(SeizureLogDto log) async {
    try {
      await _db
          .collection(FirebaseCollectionKeys.seizureLogs)
          .doc(log.id)
          .set(log.toMap());
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<ResultDto<void>> createAlert(AlertDto alert) async {
    try {
      await _db
          .collection(FirebaseCollectionKeys.alerts)
          .doc(alert.id)
          .set(alert.toMap(), SetOptions(merge: true));
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<ResultDto<void>> updateAlertStatus(
    String alertId,
    AlertStatus status,
  ) async {
    try {
      await _db.collection(FirebaseCollectionKeys.alerts).doc(alertId).update({
        'status': status.name,
        'resolvedAt': status == AlertStatus.resolved
            ? DateTime.now().toIso8601String()
            : null,
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

  Future<ResultDto<void>> upsertHeadsUp(HeadsUpDto headsUp) async {
    try {
      await _db
          .collection(FirebaseCollectionKeys.headsUp)
          .doc(headsUp.id)
          .set(headsUp.toMap());
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
        .map(
          (s) => s.docs.map((d) => AlertResponseDto.fromMap(d.data())).toList(),
        );
  }

  Stream<List<AlertDeliveryDto>> watchAlertDeliveries(String alertId) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _db
        .collection('alert_deliveries')
        .where('alertId', isEqualTo: alertId)
        .where('alertOwnerId', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => AlertDeliveryDto.fromMap(document.data()))
              .toList(),
        );
  }
}
