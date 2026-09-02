import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/alert_detail_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/services/call_service.dart';
import 'package:seizure_app/core/services/caregiver_service.dart';
import 'package:seizure_app/core/services/location_service.dart';
import 'package:seizure_app/core/services/map_launcher_service.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/constants/snackbar_margin.dart';

class IncomingAlertViewModel extends GetxController {
  IncomingAlertViewModel(this._alertId, this._caregiverService);

  final String _alertId;
  final CaregiverService _caregiverService;

  final Rxn<AlertDetailDto> detail = Rxn<AlertDetailDto>();
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;
  final RxBool isResponding = false.obs;
  final Rxn<double> distanceMeters = Rxn<double>();

  final Rx<Duration> elapsed = Duration.zero.obs;
  Timer? _ticker;

  @override
  void onInit() {
    super.onInit();
    unawaited(_load());
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
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

    _startTicker();
    unawaited(_markSeen());
    unawaited(_computeDistance());
  }

  void _startTicker() {
    _tick();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final DateTime? createdAt = detail.value?.alert.createdAt;
    if (createdAt == null) return;
    final Duration since = DateTime.now().difference(createdAt);
    elapsed.value = since.isNegative ? Duration.zero : since;
  }

  Future<void> _markSeen() async {
    final current = detail.value;
    if (current == null) return;
    await _caregiverService.submitAlertResponse(alertId: current.alert.id);
  }

  Future<void> _computeDistance() async {
    final alert = detail.value?.alert;
    final lat = alert?.latitude;
    final lng = alert?.longitude;
    if (lat == null || lng == null) return;

    final position = await LocationService.instance().getCurrentPosition();
    if (position == null) return;

    distanceMeters.value = Geolocator.distanceBetween(position.latitude, position.longitude, lat, lng);
  }

  String get elapsedClock {
    final Duration since = elapsed.value;
    final String mm = since.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String ss = since.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (since.inHours > 0) return '${since.inHours}:$mm:$ss';
    return '$mm:$ss';
  }

  String? distanceLabel() {
    final meters = distanceMeters.value;
    if (meters == null) return null;
    if (meters < 1000) return '${meters.round()} m from you';
    return '${(meters / 1000).toStringAsFixed(1)} km from you';
  }

  String elapsedLabel() {
    final createdAt = detail.value?.alert.createdAt;
    if (createdAt == null) return '';
    final minutes = DateTime.now().difference(createdAt).inMinutes;
    if (minutes < 1) return 'Just now';
    return '$minutes min ago';
  }

  String get summaryLine {
    final AlertDetailDto? current = detail.value;
    if (current == null) return '';
    final String firstName = current.ownerProfile.displayName.split(' ').first;

    final int others = (current.notifiedCount - 1).clamp(0, 999);
    final String who = switch (others) {
      0 => 'You were notified.',
      1 => 'You and 1 other were notified.',
      _ => 'You and $others others were notified.',
    };
    return '$firstName sent an SOS and did not cancel. $who';
  }

  String? get primaryMedication {
    final List<String> meds = detail.value?.ownerProfile.medications ?? const <String>[];
    return meds.isEmpty ? null : meds.first;
  }

  bool get hasLocation => detail.value?.alert.latitude != null && detail.value?.alert.longitude != null;

  Future<void> respond() async {
    final current = detail.value;
    if (current == null || isResponding.value) return;

    isResponding.value = true;
    final ResultDto<void> result = await _caregiverService.submitAlertResponse(
      alertId: current.alert.id,
      responding: true,
    );
    isResponding.value = false;

    if (!result.isSuccess) {
      Get.snackbar(
        'Could not respond',
        'Your response was not recorded. Check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      margin: snackbarMargin,
      );
      return;
    }

    Get.offNamed(AppRoutes.responding, arguments: <String, String>{'alertId': current.alert.id});
  }

  Future<void> callOwner() => CallService.call(detail.value?.ownerProfile.phone);

  Future<void> openDirections() async {
    final alert = detail.value?.alert;
    if (alert?.latitude == null || alert?.longitude == null) return;
    await MapLauncherService.openDirections(
      latitude: alert!.latitude!,
      longitude: alert.longitude!,
      label: detail.value?.ownerProfile.displayName,
    );
  }
}

class IncomingAlertBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as Map?;
    final alertId = (args?['alertId'] as String?) ?? Get.parameters['alertId'] ?? '';
    Get.lazyPut(() => IncomingAlertViewModel(alertId, CaregiverService.instance()));
  }
}
