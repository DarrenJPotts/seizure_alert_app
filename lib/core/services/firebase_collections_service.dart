import 'package:seizure_app/core/dtos/daily_log_dto.dart';
import 'package:seizure_app/core/dtos/cycle_tracking_dto.dart';
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
import 'package:seizure_app/core/dtos/medication_reminder_dto.dart';

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

  /// A transaction preserves other reminders when two devices update the list.
  Future<ResultDto<List<MedicationReminderDto>>> updateReminders(
    String uid,
    List<MedicationReminderDto> Function(List<MedicationReminderDto>) change,
  ) async {
    try {
      if (uid.isEmpty) return ResultDto.failure('Sign in to manage reminders.');
      final ref = _db.collection(FirebaseCollectionKeys.users).doc(uid);
      final saved = await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) throw StateError('User not found');
        final current = (snapshot.data()?['medicationReminders'] as List? ?? [])
            .whereType<Map>()
            .map(
              (value) => MedicationReminderDto.fromMap(
                Map<String, dynamic>.from(value),
              ),
            )
            .toList();
        final next = change(current);
        if (next.length > 20 ||
            next.map((e) => e.id).toSet().length != next.length ||
            next.any((e) => e.validationError != null)) {
          throw StateError('Invalid reminders');
        }
        transaction.update(ref, {
          'medicationReminders': next.map((e) => e.toMap()).toList(),
        });
        return next;
      });
      return ResultDto.success(saved);
    } catch (_) {
      return ResultDto.failure(
        'Could not save. Refresh your reminders and try again.',
      );
    }
  }

  Future<ResultDto<DailyLogDto?>> getDailyLog(String uid, DateTime day) async {
    if (uid.isEmpty) {
      return ResultDto.failure('Sign in to view your daily log.');
    }
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('dailyLogs')
          .doc(dailyDateKey(day))
          .get();
      return ResultDto.success(
        doc.exists ? DailyLogDto.fromMap(doc.data()!) : null,
      );
    } catch (_) {
      return ResultDto.failure(
        'Your daily entry could not be loaded. Try again.',
      );
    }
  }

  Stream<List<DailyLogDto>> watchDailyLogs(
    String uid,
    DateTime start,
    DateTime end,
  ) {
    if (uid.isEmpty) return Stream.error(StateError('Sign in required'));
    return _db
        .collection('users')
        .doc(uid)
        .collection('dailyLogs')
        .where('date', isGreaterThanOrEqualTo: dailyDateKey(start))
        .where('date', isLessThanOrEqualTo: dailyDateKey(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DailyLogDto.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<ResultDto<List<DailyLogDto>>> getDailyLogs(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    if (uid.isEmpty) {
      return ResultDto.failure('Sign in to share daily entries.');
    }
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('dailyLogs')
          .where('date', isGreaterThanOrEqualTo: dailyDateKey(start))
          .where('date', isLessThanOrEqualTo: dailyDateKey(end))
          .orderBy('date', descending: true)
          .get();
      return ResultDto.success(
        snapshot.docs.map((doc) => DailyLogDto.fromMap(doc.data())).toList(),
      );
    } catch (_) {
      return ResultDto.failure('Daily entries could not be loaded.');
    }
  }

  Future<ResultDto<DailyLogDto>> saveDailyLog(
    String uid,
    DailyLogDto entry, {
    DailyLogDto? expected,
  }) async {
    if (uid.isEmpty) {
      return ResultDto.failure('Sign in to save your daily entry.');
    }
    final validation = entry.validate(DateTime.now());
    if (validation != null) return ResultDto.failure(validation);
    try {
      final owner = _db.collection('users').doc(uid);
      final ref = owner.collection('dailyLogs').doc(dailyDateKey(entry.date));
      final saved = await _db.runTransaction((transaction) async {
        if (!(await transaction.get(owner)).exists) {
          throw StateError('Profile missing');
        }
        final snapshot = await transaction.get(ref);
        final current = snapshot.exists
            ? DailyLogDto.fromMap(snapshot.data()!)
            : null;
        if (current?.revision != expected?.revision ||
            current?.updatedAt != expected?.updatedAt) {
          throw StateError('Daily entry changed');
        }
        final next = entry.saved((current?.revision ?? 0) + 1, DateTime.now());
        transaction.set(ref, next.toMap());
        return next;
      });
      return ResultDto.success(saved);
    } catch (_) {
      return ResultDto.failure(
        'Could not save. Refresh the daily entry and review your changes before trying again.',
      );
    }
  }

  Future<ResultDto<void>> deleteDailyLog(
    String uid,
    DailyLogDto expected,
  ) async {
    if (uid.isEmpty) {
      return ResultDto.failure('Sign in to remove a daily entry.');
    }
    try {
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('dailyLogs')
          .doc(dailyDateKey(expected.date));
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) return;
        final current = DailyLogDto.fromMap(snapshot.data()!);
        if (current.revision != expected.revision ||
            current.updatedAt != expected.updatedAt) {
          throw StateError('Daily entry changed');
        }
        transaction.delete(ref);
      });
      return ResultDto.success(null);
    } catch (_) {
      return ResultDto.failure(
        'Could not remove. Refresh the daily entry and try again.',
      );
    }
  }

  Future<ResultDto<CycleTrackingDto>> getCycleTracking(String uid) async {
    if (uid.isEmpty) {
      return ResultDto.failure('Sign in to view cycle tracking.');
    }
    try {
      final snapshot = await _db
          .collection(FirebaseCollectionKeys.users)
          .doc(uid)
          .get();
      if (!snapshot.exists) {
        return ResultDto.failure('Your profile could not be found.');
      }
      return ResultDto.success(
        CycleTrackingDto.fromMap(
          snapshot.data()?['cycleTracking'] == null
              ? null
              : Map<String, dynamic>.from(
                  snapshot.data()!['cycleTracking'] as Map,
                ),
        ),
      );
    } catch (_) {
      return ResultDto.failure(
        'Cycle tracking could not be loaded. Try again.',
      );
    }
  }

  Future<ResultDto<CycleTrackingDto>> updateCycleTracking(
    String uid,
    int expectedRevision,
    CycleTrackingDto Function(CycleTrackingDto) change,
  ) async {
    if (uid.isEmpty) {
      return ResultDto.failure('Sign in to manage cycle tracking.');
    }
    try {
      final ref = _db.collection(FirebaseCollectionKeys.users).doc(uid);
      final saved = await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) throw StateError('Profile missing');
        final raw = snapshot.data()?['cycleTracking'];
        final current = CycleTrackingDto.fromMap(
          raw == null ? null : Map<String, dynamic>.from(raw as Map),
        );
        if (current.revision != expectedRevision) {
          throw StateError('Changed on another device');
        }
        final next = change(current);
        if (next.revision != current.revision + 1 ||
            next.entries.length > 120 ||
            next.entries.map((entry) => entry.id).toSet().length !=
                next.entries.length ||
            next.entries.any(
              (entry) => entry.validate(DateTime.now()) != null,
            )) {
          throw StateError('Invalid cycle data');
        }
        transaction.update(ref, {'cycleTracking': next.toMap()});
        return next;
      });
      return ResultDto.success(saved);
    } catch (_) {
      return ResultDto.failure(
        'Could not save. Refresh cycle tracking and try again.',
      );
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
