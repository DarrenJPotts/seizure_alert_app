import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/constants/snackbar_margin.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/dtos/alert_response_dto.dart';
import 'package:seizure_app/core/dtos/alert_delivery_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/location_service.dart';
import 'package:seizure_app/core/services/home_widget_service.dart';
import 'package:seizure_app/core/services/local_notifications_service.dart';
import 'package:seizure_app/features/seizure_log/view_models/seizure_log_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seizure_app/core/constants/firebase_collection_keys.dart';

///
/// Firestore's offline cache acknowledges a write locally and completes the
/// `set()` future only once the *server* has it. Offline that future simply
/// never completes, so the old code sat on an unresolved `await` while the
/// screen showed a live alert — the user believed their circle had been told
/// when nothing had left the phone. That is the worst failure this app has,
/// and it was invisible.
enum SosDelivery { sending, delivered, queued, failed }

class SosViewModel extends GetxController {
  static const _storageKey = 'active_sos';

  static const Duration deliveryGrace = Duration(seconds: 8);

  final Rxn<AlertDto> activeSos = Rxn<AlertDto>();
  final Rx<Duration> elapsed = Duration.zero.obs;
  final RxList<AlertResponseDto> alertResponses = <AlertResponseDto>[].obs;
  final RxList<AlertDeliveryDto> alertDeliveries = <AlertDeliveryDto>[].obs;
  final Rx<SosDelivery> delivery = SosDelivery.delivered.obs;

  Timer? _elapsedTimer;
  Timer? _deliveryWatchdog;
  StreamSubscription<List<AlertResponseDto>>? _responsesSub;
  StreamSubscription<List<AlertDeliveryDto>>? _deliveriesSub;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _restoreActiveSos();
  }

  @override
  void onClose() {
    _elapsedTimer?.cancel();
    _deliveryWatchdog?.cancel();
    _responsesSub?.cancel();
    _deliveriesSub?.cancel();
    super.onClose();
  }

  /// True while the circle has *not* been told, for whatever reason.
  bool get isUndelivered =>
      delivery.value == SosDelivery.queued ||
      delivery.value == SosDelivery.failed;

  Future<void> _restoreActiveSos() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? json = prefs.getString(_storageKey);
      if (json == null) return;

      final AlertDto dto = AlertDto.fromMap(jsonDecode(json));
      if (dto.status == AlertStatus.sent) {
        activeSos.value = dto;
        _syncHomeWidget();
        _startElapsed();
        _watchResponses(dto.id);
        // Re-issuing the write is idempotent (same deterministic id) and is
        // the only way to learn whether the original one ever landed — the
        // app may have been killed before it did.
        _trackDelivery(dto.id, FirestoreService.instance().createAlert(dto));
      } else if (dto.status == AlertStatus.cancelled ||
          dto.status == AlertStatus.resolved) {
        unawaited(
          FirestoreService.instance().updateAlertStatus(dto.id, dto.status),
        );
      }
    } catch (e) {
      debugPrint('[SosVM] Error restoring active SOS: $e');
    }
  }

  Future<void> startSos() async {
    try {
      Get.find<SeizureLogViewModel>().addEntry(
        occurredAt: DateTime.now(),
        alertFired: true,
      );

      final DateTime now = DateTime.now();
      final String id = FirestoreService.instance().newDocumentId(
        FirebaseCollectionKeys.alerts,
      );
      final AlertDto alert = AlertDto(
        id: id,
        userId: _uid,
        type: AlertType.sos,
        status: AlertStatus.sent,
        createdAt: now,
      );

      await _persist(alert);
      activeSos.value = alert;
      _syncHomeWidget();
      _startElapsed();
      _watchResponses(alert.id);
      unawaited(_startNearbyAlert());

      _trackDelivery(alert.id, FirestoreService.instance().createAlert(alert));

      final Position? position = await LocationService.instance()
          .getCurrentPosition();
      if (position == null) return;

      if (activeSos.value?.id != alert.id) return;

      final AlertDto located = alert.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      await _persist(located);
      activeSos.value = located;

      unawaited(
        FirestoreService.instance().createAlert(located).then((
          ResultDto<void> r,
        ) {
          if (!r.isSuccess) {
            debugPrint('[SosVM] Error attaching location: ${r.error}');
          }
        }),
      );
    } catch (e) {
      debugPrint('[SosVM] Error starting SOS: $e');
      delivery.value = SosDelivery.failed;
    }
  }

  void _trackDelivery(String alertId, Future<ResultDto<void>> write) {
    delivery.value = SosDelivery.sending;

    _deliveryWatchdog?.cancel();
    _deliveryWatchdog = Timer(deliveryGrace, () {
      if (activeSos.value?.id == alertId &&
          delivery.value == SosDelivery.sending) {
        delivery.value = SosDelivery.queued;
      }
    });

    unawaited(
      write.then((ResultDto<void> result) {
        if (activeSos.value?.id != alertId) return;
        _deliveryWatchdog?.cancel();

        if (result.isSuccess) {
          delivery.value = SosDelivery.delivered;
        } else {
          debugPrint('[SosVM] Alert write rejected: ${result.error}');
          delivery.value = SosDelivery.failed;
        }
      }),
    );
  }

  Future<void> cancelSos() async {
    final AlertDto? current = activeSos.value;
    if (current == null) return;

    try {
      _elapsedTimer?.cancel();
      _responsesSub?.cancel();
      _deliveriesSub?.cancel();

      final AlertDto updated = current.copyWith(
        status: AlertStatus.cancelled,
        resolvedAt: DateTime.now(),
      );
      await _persist(updated);
      activeSos.value = null;
      _syncHomeWidget();
      elapsed.value = Duration.zero;
      alertResponses.clear();
      alertDeliveries.clear();
      if (Get.isRegistered<LocalNotificationsService>()) {
        unawaited(
          Get.find<LocalNotificationsService>().cancelNearbyEmergencyAlert(),
        );
      }

      _deliveryWatchdog?.cancel();
      delivery.value = SosDelivery.delivered;

      // Same reasoning as the send path: offline this never resolves, so it
      // cannot be awaited. The difference is what a failure means — the
      // circle still believes the alert is live, which they must be told.
      unawaited(
        FirestoreService.instance()
            .updateAlertStatus(current.id, AlertStatus.cancelled)
            .timeout(
              deliveryGrace,
              onTimeout: () => ResultDto<void>.failure('timed out'),
            )
            .then((ResultDto<void> result) {
              if (result.isSuccess) {
                _showSnackbar(
                  'Alert cancelled',
                  'Your circle has been told you are OK.',
                );
              } else {
                debugPrint('[SosVM] Error cancelling alert: ${result.error}');
                _showErrorSnackbar(
                  'Cancellation not sent',
                  'Your circle may still think this alert is active. Call them.',
                );
              }
            }),
      );
    } catch (e) {
      debugPrint('[SosVM] Error cancelling SOS: $e');
      _showErrorSnackbar(
        'Not Updated',
        'Your circle may still think this alert is active.',
      );
    }
  }

  void _watchResponses(String alertId) {
    _responsesSub?.cancel();
    _responsesSub = FirestoreService.instance()
        .watchAlertResponses(alertId)
        .listen(
          (List<AlertResponseDto> list) => alertResponses.value = list,
          onError: (Object e) =>
              debugPrint('[SosVM] Error watching responses: $e'),
        );
    _deliveriesSub?.cancel();
    _deliveriesSub = FirestoreService.instance()
        .watchAlertDeliveries(alertId)
        .listen(
          (List<AlertDeliveryDto> list) => alertDeliveries.value = list,
          onError: (Object error) =>
              debugPrint('[SosVM] Error watching deliveries: $error'),
        );
  }

  void _startElapsed() {
    _elapsedTimer?.cancel();
    _tick();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final AlertDto? current = activeSos.value;
    if (current == null) return;
    elapsed.value = DateTime.now().difference(current.createdAt);
  }

  String formattedElapsed() {
    final Duration d = elapsed.value;
    final int m = d.inMinutes;
    final int s = d.inSeconds.remainder(60);
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }

  Future<void> _persist(AlertDto alert) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(alert.toMap()));
    } catch (e) {
      debugPrint('[SosVM] Error persisting active SOS: $e');
      rethrow;
    }
  }

  void _syncHomeWidget() {
    if (Get.isRegistered<HomeWidgetService>()) {
      unawaited(Get.find<HomeWidgetService>().syncCurrentState());
    }
  }

  Future<void> _startNearbyAlert() async {
    if (!Get.isRegistered<LocalNotificationsService>()) return;
    final result = await FirestoreService.instance().getUser(_uid);
    final user = result.data;
    if (!result.isSuccess || user?.nearbyAudibleAlert != true) return;
    await Get.find<LocalNotificationsService>().showNearbyEmergencyAlert(
      user?.seizureActionPlan ?? user?.emergencyNote ?? '',
    );
  }

  void _showSnackbar(String title, String message) {
    Get.snackbar(
      '',
      '',
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      messageText: Text(message, style: const TextStyle(color: Colors.white)),
      snackPosition: SnackPosition.BOTTOM,
      margin: snackbarMargin,
      backgroundColor: Colors.black,
      borderRadius: Dimensions.eight,
      duration: const Duration(seconds: 3),
    );
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      '',
      '',
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      messageText: Text(message, style: const TextStyle(color: Colors.white)),
      snackPosition: SnackPosition.BOTTOM,
      margin: snackbarMargin,
      backgroundColor: Colors.red.shade700,
      borderRadius: Dimensions.eight,
      duration: const Duration(seconds: 4),
    );
  }
}
