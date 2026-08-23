import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/alert_detail_dto.dart';
import 'package:seizure_app/core/dtos/alert_response_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/caregiver_service.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/location_service.dart';
import 'package:seizure_app/core/services/call_service.dart';

class IncomingAlertViewModel extends GetxController {
  IncomingAlertViewModel(this._alertId, this._caregiverService);

  final String _alertId;
  final CaregiverService _caregiverService;

  final Rxn<AlertDetailDto> detail = Rxn<AlertDetailDto>();
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;
  final RxBool isResponding = false.obs;
  final Rxn<double> distanceMeters = Rxn<double>();

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    screenState.value = GenericScreenStates.loading;
    final result = await _caregiverService.getAlertDetail(_alertId);
    if (!result.isSuccess || result.data == null) {
      screenState.value = GenericScreenStates.error;
      return;
    }
    detail.value = result.data;
    screenState.value = GenericScreenStates.loaded;

    _markSeen();
    _computeDistance();
  }

  Future<void> _markSeen() async {
    final current = detail.value;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (current == null || uid == null) return;

    await FirestoreService.instance().upsertAlertResponse(AlertResponseDto(
      id: '${current.alert.id}_${current.callerContactId}',
      alertId: current.alert.id,
      alertOwnerId: current.alert.userId,
      contactId: current.callerContactId,
      contactName: current.callerContactName,
      responderId: uid,
      seen: true,
      seenAt: DateTime.now(),
    ));
  }

  Future<void> _computeDistance() async {
    final alert = detail.value?.alert;
    final lat = alert?.latitude;
    final lng = alert?.longitude;
    if (lat == null || lng == null) return;

    final position = await LocationService.instance().getCurrentPosition();
    if (position == null) return;

    distanceMeters.value = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      lat,
      lng,
    );
  }

  String? distanceLabel() {
    final meters = distanceMeters.value;
    if (meters == null) return null;
    if (meters < 1000) return '${meters.round()} m away';
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  String elapsedLabel() {
    final createdAt = detail.value?.alert.createdAt;
    if (createdAt == null) return '';
    final minutes = DateTime.now().difference(createdAt).inMinutes;
    if (minutes < 1) return 'Just now';
    return '$minutes min ago';
  }

  Future<void> respond() async {
    final current = detail.value;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (current == null || uid == null || isResponding.value) return;

    isResponding.value = true;
    await FirestoreService.instance().upsertAlertResponse(AlertResponseDto(
      id: '${current.alert.id}_${current.callerContactId}',
      alertId: current.alert.id,
      alertOwnerId: current.alert.userId,
      contactId: current.callerContactId,
      contactName: current.callerContactName,
      responderId: uid,
      seen: true,
      responding: true,
      respondedAt: DateTime.now(),
    ));
    isResponding.value = false;
  }

  Future<void> callOwner() =>
      CallService.call(detail.value?.ownerProfile.phone);
}

class IncomingAlertBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as Map?;
    final alertId = (args?['alertId'] as String?) ?? Get.parameters['alertId'] ?? '';
    Get.lazyPut(
        () => IncomingAlertViewModel(alertId, CaregiverService.instance()));
  }
}
