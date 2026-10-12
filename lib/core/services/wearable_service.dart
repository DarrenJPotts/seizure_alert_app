import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/firebase_collection_keys.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/dtos/wearable_device_dto.dart';

class WearablePairingCode {
  const WearablePairingCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

class WearableService {
  WearableService(this._functions, this._firestore);

  static WearableService instance() => Get.isRegistered<WearableService>()
      ? Get.find<WearableService>()
      : Get.put(
          WearableService(
            FirebaseFunctions.instance,
            FirebaseFirestore.instance,
          ),
        );

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Stream<List<WearableDeviceDto>> watchDevices() {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _firestore
        .collection(FirebaseCollectionKeys.wearableDevices)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> document) =>
                    WearableDeviceDto.fromMap(document.data()),
              )
              .toList(),
        );
  }

  Future<ResultDto<WearablePairingCode>> createPairingCode() async {
    try {
      final HttpsCallableResult<dynamic> response = await _functions
          .httpsCallable('createWearablePairingCode')
          .call();
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.data as Map,
      );
      return ResultDto.success(
        WearablePairingCode(
          code: data['code'] as String,
          expiresAt: DateTime.fromMillisecondsSinceEpoch(
            (data['expiresAt'] as num).toInt(),
          ),
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      return ResultDto.failure(
        error.code == 'resource-exhausted'
            ? 'Wait before creating another pairing code.'
            : 'A pairing code could not be created.',
      );
    } catch (_) {
      return ResultDto.failure('A pairing code could not be created.');
    }
  }

  Future<ResultDto<void>> removeDevice(String deviceId) async {
    try {
      await _functions.httpsCallable('removeWearableDevice').call(
        <String, String>{'deviceId': deviceId},
      );
      return ResultDto.success(null);
    } catch (_) {
      return ResultDto.failure('The wearable could not be removed.');
    }
  }
}
