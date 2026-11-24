import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/dtos/alert_detail_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/services/call_service.dart';
import 'package:seizure_app/core/services/caregiver_service.dart';
import 'package:seizure_app/core/services/firebase_messaging_service.dart';
import 'package:seizure_app/core/services/location_service.dart';
import 'package:seizure_app/core/services/map_launcher_service.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/helpers/app_snackbar.dart';

class IncomingAlertViewModel extends GetxController {
  IncomingAlertViewModel(this._alertId, this._caregiverService);

  final String _alertId;
  final CaregiverService _caregiverService;

  final Rxn<AlertDetailDto> detail = Rxn<AlertDetailDto>();
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;
  final RxBool isResponding = false.obs;
  final Rxn<double> distanceMeters = Rxn<double>();

  final Rx<Duration> elapsed = Duration.zero.obs;

  /// Set when the load failed because the alert no longer exists or this
  /// caregiver can no longer see it. Any other failure (offline, a timeout)
  /// is shown as "couldn't load" with a retry, never as "alert gone".
  final RxBool alertGone = false.obs;

  /// Error codes from getAlertDetail that mean the alert itself is gone.
  static const Set<String> goneErrorCodes = <String>{
    'not-found',
    'permission-denied',
    'invalid-argument',
  };

  /// The phone writes the alert first and adds GPS a few seconds later, so a
  /// caregiver who opens the push at once can load it before the location.
  static const Duration locationPollInterval = Duration(seconds: 10);
  static const int maxLocationPolls = 12;

  int _loadGeneration = 0;
  int _locationPolls = 0;
  Timer? _ticker;
  Timer? _locationPoll;
  Worker? _notificationWorker;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<FirebaseMessagingService>()) {
      _notificationWorker = ever<RemoteMessage?>(
        Get.find<FirebaseMessagingService>().lastNotification,
        _handleNotification,
      );
    }
    unawaited(_load());
  }

  @override
  void onClose() {
    ++_loadGeneration;
    _ticker?.cancel();
    _locationPoll?.cancel();
    _notificationWorker?.dispose();
    super.onClose();
  }

  void _handleNotification(RemoteMessage? message) {
    if (message == null || message.data['alertId'] != _alertId) return;
    if (message.data['alertStatus'] == AlertStatus.sent.name) return;
    unawaited(_load(showLoading: false));
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) screenState.value = GenericScreenStates.loading;
    if (isClosed) return;
    final request = ++_loadGeneration;
    final result = await _caregiverService.getAlertDetail(_alertId);
    if (isClosed || request != _loadGeneration) return;
    if (!result.isSuccess || result.data == null) {
      final bool gone = goneErrorCodes.contains(result.error);
      // A failed background refresh keeps the alert already on screen.
      if (detail.value != null && !gone) {
        _scheduleLocationPoll();
        return;
      }
      alertGone.value = gone;
      screenState.value = GenericScreenStates.error;
      return;
    }
    alertGone.value = false;
    detail.value = result.data;
    screenState.value = GenericScreenStates.loaded;
    _scheduleLocationPoll();

    if (isAlertActive) {
      _startTicker();
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
    if (isAlertActive) unawaited(_markSeen());
    unawaited(_computeDistance());
  }

  /// Reloads the alert. Used by the "Try again" button.
  Future<void> retry() => _load();

  void _scheduleLocationPoll() {
    _locationPoll?.cancel();
    _locationPoll = null;
    if (!isAlertActive || hasLocation || _locationPolls >= maxLocationPolls) {
      return;
    }
    _locationPoll = Timer(locationPollInterval, () {
      _locationPolls++;
      unawaited(_load(showLoading: false));
    });
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
    if (isClosed || position == null || detail.value?.alert.id != alert?.id) {
      return;
    }

    distanceMeters.value = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      lat,
      lng,
    );
  }

  String get elapsedClock {
    final Duration since = elapsed.value;
    final String mm = since.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String ss = since.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (since.inHours > 0) return '${since.inHours}:$mm:$ss';
    return '$mm:$ss';
  }

  bool get isAlertActive => detail.value?.alert.status == AlertStatus.sent;

  bool get isMissedCheckIn =>
      detail.value?.alert.type == AlertType.headsUpExpired;

  /// The chip above the heading.
  String get typeLabel => isMissedCheckIn ? 'CHECK-IN MISSED' : 'SOS';

  DateTime? get startedAt => detail.value?.alert.createdAt.toLocal();

  int get callEmergencyAfterMinutes =>
      detail.value?.ownerProfile.callEmergencyAfterMinutes ?? 0;

  /// Read by screen readers instead of the per-second clock.
  String startedSemantics(String Function(DateTime) formatTime) {
    final DateTime? started = startedAt;
    if (started == null) return 'Live alert';
    return 'Live alert, started at ${formatTime(started)}';
  }

  String get alertStatusLabel => switch (detail.value?.alert.status) {
    AlertStatus.cancelled => 'CANCELLED',
    AlertStatus.resolved => 'RESOLVED',
    _ => 'LIVE · STARTED $elapsedClock AGO',
  };

  String get heading {
    final AlertDetailDto? current = detail.value;
    if (current == null) return '';
    final String firstName = current.ownerProfile.displayName.split(' ').first;
    return switch (current.alert.status) {
      AlertStatus.cancelled => '$firstName cancelled the alert',
      AlertStatus.resolved => '$firstName resolved the alert',
      AlertStatus.sent =>
        isMissedCheckIn
            ? '$firstName missed a check-in'
            : '$firstName needs help',
    };
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

    if (current.alert.status == AlertStatus.cancelled) {
      return '$firstName indicated they are okay. Call if you still have concerns.';
    }
    if (current.alert.status == AlertStatus.resolved) {
      return 'This alert has been marked as resolved.';
    }

    final int others = (current.notifiedCount - 1).clamp(0, 999);
    final String who = switch (others) {
      0 => 'You were notified.',
      1 => 'You and 1 other were notified.',
      _ => 'You and $others others were notified.',
    };
    if (isMissedCheckIn) {
      return '$firstName started a Heads Up and did not check in before it ran out. $who';
    }
    return '$firstName sent an SOS and did not cancel. $who';
  }

  String? get primaryMedication {
    final List<String> meds =
        detail.value?.ownerProfile.medications ?? const <String>[];
    return meds.isEmpty ? null : meds.first;
  }

  bool get hasLocation =>
      detail.value?.alert.latitude != null &&
      detail.value?.alert.longitude != null;

  Future<void> respond() async {
    final current = detail.value;
    if (current == null || !isAlertActive || isResponding.value) return;

    isResponding.value = true;
    final ResultDto<void> result = await _caregiverService.submitAlertResponse(
      alertId: current.alert.id,
      responding: true,
    );
    if (isClosed) return;
    isResponding.value = false;

    if (!result.isSuccess) {
      showAppSnackbar(
        'Could not respond',
        'Your response was not recorded. Check your connection and try again.',
      );
      return;
    }

    Get.offNamed(
      AppRoutes.responding,
      arguments: <String, String>{'alertId': current.alert.id},
    );
  }

  Future<void> callOwner() =>
      CallService.call(detail.value?.ownerProfile.phone);

  Future<void> callEmergency() => CallService.callEmergency();

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
    final alertId =
        (args?['alertId'] as String?) ?? Get.parameters['alertId'] ?? '';
    Get.lazyPut(
      () => IncomingAlertViewModel(alertId, CaregiverService.instance()),
    );
  }
}
