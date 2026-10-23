import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/dtos/wearable_device_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/firebase_messaging_service.dart';
import 'package:seizure_app/core/services/network_status_service.dart';
import 'package:seizure_app/core/services/wearable_service.dart';

class SafetyReadinessViewModel extends GetxController {
  SafetyReadinessViewModel(
    this._firestore,
    this._messaging,
    this._network,
    this._wearables,
  );

  final FirestoreService _firestore;
  final FirebaseMessagingService? _messaging;
  final NetworkStatusService _network;
  final WearableService _wearables;

  final RxList<ContactDto> contacts = <ContactDto>[].obs;
  final RxList<WearableDeviceDto> devices = <WearableDeviceDto>[].obs;
  final RxBool locationReady = false.obs;
  final RxBool loading = true.obs;
  final RxBool creatingPairingCode = false.obs;
  final RxnString removingDeviceId = RxnString();
  final RxnString error = RxnString();

  StreamSubscription<List<ContactDto>>? _contactsSubscription;
  StreamSubscription<List<WearableDeviceDto>>? _wearablesSubscription;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  RxBool get networkAvailable => _network.hasNetwork;
  bool get notificationsReady =>
      _messaging?.notificationsAuthorized == true &&
      _messaging?.fcmRegistrationReady.value == true;
  int get readyCaregiverCount =>
      contacts.where((ContactDto contact) => contact.isPushReady).length;
  int get testedCaregiverCount => contacts
      .where(
        (ContactDto contact) =>
            contact.isPushReady &&
            contact.lastTestStatus == ContactAlertTestStatus.sent,
      )
      .length;
  DateTime? get lastCaregiverTest {
    final List<DateTime> dates =
        contacts
            .map((ContactDto contact) => contact.lastTestedAt)
            .whereType<DateTime>()
            .toList()
          ..sort((DateTime a, DateTime b) => b.compareTo(a));
    return dates.isEmpty ? null : dates.first;
  }

  @override
  void onInit() {
    super.onInit();
    refreshReadiness();
    _contactsSubscription = _firestore
        .watchContacts(_uid)
        .listen(
          (List<ContactDto> value) {
            contacts.assignAll(value);
            loading.value = false;
          },
          onError: (_) {
            error.value = 'Safety readiness could not be checked.';
            loading.value = false;
          },
        );
    _wearablesSubscription = _wearables.watchDevices().listen(
      devices.assignAll,
      onError: (_) {},
    );
  }

  Future<void> refreshReadiness() async {
    loading.value = true;
    error.value = null;
    try {
      await _messaging?.refreshReadiness();
      if (isClosed) return;
      final granted = await Permission.locationWhenInUse.isGranted;
      if (isClosed) return;
      locationReady.value = granted;
    } catch (_) {
      if (!isClosed) {
        error.value = 'Readiness could not be refreshed. Try again.';
      }
    } finally {
      if (!isClosed) loading.value = false;
    }
  }

  Future<ResultDto<WearablePairingCode>> createPairingCode() async {
    if (creatingPairingCode.value) {
      return ResultDto.failure('A pairing code is already being created.');
    }
    creatingPairingCode.value = true;
    try {
      return await _wearables.createPairingCode();
    } finally {
      if (!isClosed) creatingPairingCode.value = false;
    }
  }

  Future<String?> removeDevice(String deviceId) async {
    if (removingDeviceId.value != null) return null;
    removingDeviceId.value = deviceId;
    try {
      final result = await _wearables.removeDevice(deviceId);
      return result.isSuccess ? null : result.error;
    } finally {
      if (!isClosed) removingDeviceId.value = null;
    }
  }

  @override
  void onClose() {
    _contactsSubscription?.cancel();
    _wearablesSubscription?.cancel();
    super.onClose();
  }
}

class SafetyReadinessBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SafetyReadinessViewModel(
        FirestoreService.instance(),
        Get.isRegistered<FirebaseMessagingService>()
            ? Get.find<FirebaseMessagingService>()
            : null,
        Get.find<NetworkStatusService>(),
        WearableService.instance(),
      ),
    );
  }
}
