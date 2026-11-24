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
import 'package:seizure_app/core/helpers/app_snackbar.dart';

///
/// Firestore's offline cache acknowledges a write locally and completes the
/// `set()` future only once the *server* has it. Offline that future simply
/// never completes, so the old code sat on an unresolved `await` while the
/// screen showed a live alert — the user believed their circle had been told
/// when nothing had left the phone. That is the worst failure this app has,
/// and it was invisible.
///
/// [notNotified] covers the next gap: the server has the alert, but no contact
/// was sent a push within [SosViewModel.notifyGrace] — or every push failed.
/// The server can drop the fan-out (an outage, a disabled flag, a contact with
/// no device), and "SOS ACTIVE" would then be a lie.
enum SosDelivery { sending, delivered, queued, failed, notNotified }

class SosViewModel extends GetxController {
  SosViewModel({String? Function()? currentUid}) : _currentUid = currentUid;
  final String? Function()? _currentUid;
  static const _storageKey = 'active_sos';

  static const Duration deliveryGrace = Duration(seconds: 8);

  /// How long after the server has the alert we wait for at least one
  /// contact's push to be confirmed before telling the user nobody knows.
  static const Duration notifyGrace = Duration(seconds: 30);

  final Rxn<AlertDto> activeSos = Rxn<AlertDto>();
  final Rx<Duration> elapsed = Duration.zero.obs;
  final RxList<AlertResponseDto> alertResponses = <AlertResponseDto>[].obs;
  final RxList<AlertDeliveryDto> alertDeliveries = <AlertDeliveryDto>[].obs;
  final Rx<SosDelivery> delivery = SosDelivery.delivered.obs;

  Timer? _elapsedTimer;
  Timer? _deliveryWatchdog;
  Timer? _notifyWatchdog;
  bool _notifyGraceElapsed = false;

  /// Open SOS alerts on the server, from any device. A watch SOS used to be
  /// invisible on the phone, which could then send a second one and could
  /// not cancel the first.
  StreamSubscription<List<AlertDto>>? _openSosSub;

  /// Alerts this phone has seen open on the server, so a later absence means
  /// they were closed elsewhere (not merely not uploaded yet).
  final Set<String> _seenOnServer = <String>{};

  /// Alerts closed on this phone, so they are not adopted again while the
  /// cancel is still on its way to the server.
  final Set<String> _closedHere = <String>{};
  StreamSubscription<List<AlertResponseDto>>? _responsesSub;
  StreamSubscription<List<AlertDeliveryDto>>? _deliveriesSub;

  String get _uid =>
      (_currentUid != null
          ? _currentUid()
          : FirebaseAuth.instance.currentUser?.uid) ??
      '';
  late final String _sessionUid = _uid;
  bool get _sessionActive =>
      !isClosed && _sessionUid.isNotEmpty && _uid == _sessionUid;

  @override
  void onInit() {
    super.onInit();
    _restoreActiveSos();
    _watchOpenSos();
  }

  @override
  void onClose() {
    _elapsedTimer?.cancel();
    _deliveryWatchdog?.cancel();
    _notifyWatchdog?.cancel();
    _openSosSub?.cancel();
    _responsesSub?.cancel();
    _deliveriesSub?.cancel();
    super.onClose();
  }

  /// True while the circle has *not* been told, for whatever reason.
  bool get isUndelivered =>
      delivery.value == SosDelivery.queued ||
      delivery.value == SosDelivery.failed ||
      delivery.value == SosDelivery.notNotified;

  Future<void> _restoreActiveSos() async {
    try {
      if (!_sessionActive) return;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!_sessionActive) return;
      final String? json = prefs.getString(_storageKey);
      if (json == null) return;

      final AlertDto dto = AlertDto.fromMap(jsonDecode(json));
      if (dto.userId != _sessionUid) return;
      if (dto.status == AlertStatus.sent) {
        // The SOS may have been cancelled from the watch or another device
        // while the app was closed. Re-sending it then is rejected by the
        // rules and the screen claimed "NOT SENT. Nobody has been notified".
        final AlertStatus? serverStatus = await _serverStatus(dto.id);
        if (!_sessionActive) return;
        if (serverStatus == AlertStatus.cancelled ||
            serverStatus == AlertStatus.resolved) {
          await _persist(dto.copyWith(status: serverStatus));
          return;
        }
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

  /// The server's status for [alertId], or null if offline or unknown.
  Future<AlertStatus?> _serverStatus(String alertId) async {
    try {
      return await FirestoreService.instance()
          .fetchAlertStatus(alertId)
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  Future<void> startSos() async {
    if (!_sessionActive || activeSos.value != null) return;
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
      if (!_sessionActive) return;
      activeSos.value = alert;
      _syncHomeWidget();
      _startElapsed();
      _watchResponses(alert.id);
      unawaited(_startNearbyAlert());

      _trackDelivery(alert.id, FirestoreService.instance().createAlert(alert));

      final Position? position = await LocationService.instance()
          .getCurrentPosition();
      if (!_sessionActive || position == null) return;

      if (activeSos.value?.id != alert.id) return;

      final AlertDto located = alert.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      activeSos.value = located;
      await _persist(located);
      if (activeSos.value?.id != alert.id) {
        // Cancelled while the location was being saved. Store the cancel
        // again so the saved "sent" copy cannot bring the SOS back.
        await _persist(
          located.copyWith(
            status: AlertStatus.cancelled,
            resolvedAt: DateTime.now(),
          ),
        );
        return;
      }

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
      if (activeSos.value == null) {
        showAppSnackbar(
          'SOS not sent',
          'Something went wrong before the alert was sent. Try again or call a contact.',
        );
      }
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
        if (!_sessionActive || activeSos.value?.id != alertId) return;
        _deliveryWatchdog?.cancel();

        if (result.isSuccess) {
          delivery.value = SosDelivery.delivered;
          _startNotifyWatchdog(alertId);
        } else {
          debugPrint('[SosVM] Alert write rejected: ${result.error}');
          delivery.value = SosDelivery.failed;
        }
      }),
    );
  }

  /// Sends the active alert again after the server rejected it. The id is
  /// fixed, so this cannot create a second alert.
  void retrySend() {
    final AlertDto? current = activeSos.value;
    if (!_sessionActive || current == null) return;
    _trackDelivery(
      current.id,
      FirestoreService.instance().createAlert(current),
    );
  }

  void _startNotifyWatchdog(String alertId) {
    _notifyWatchdog?.cancel();
    _notifyGraceElapsed = false;
    _notifyWatchdog = Timer(notifyGrace, () {
      if (!_sessionActive || activeSos.value?.id != alertId) return;
      _notifyGraceElapsed = true;
      reconcileNotified();
    });
    reconcileNotified();
  }

  /// Moves between [SosDelivery.delivered] and [SosDelivery.notNotified]
  /// from the server's per-contact delivery records. Only runs once the
  /// server has the alert; the offline and rejected states take priority.
  @visibleForTesting
  void reconcileNotified({bool? graceElapsed}) {
    if (graceElapsed != null) _notifyGraceElapsed = graceElapsed;
    if (activeSos.value == null) return;
    if (delivery.value != SosDelivery.delivered &&
        delivery.value != SosDelivery.notNotified) {
      return;
    }
    final bool anySent = alertDeliveries.any(
      (AlertDeliveryDto d) => d.status == 'sent',
    );
    if (anySent) {
      delivery.value = SosDelivery.delivered;
    } else if (_notifyGraceElapsed || alertDeliveries.isNotEmpty) {
      // Either the grace period passed with no record, or the server has
      // written its records and none of them is a successful send.
      delivery.value = SosDelivery.notNotified;
    }
  }

  Future<void> cancelSos() async {
    final AlertDto? current = activeSos.value;
    if (!_sessionActive || current == null) return;

    try {
      await _clearActiveSos(current);
      if (!_sessionActive) return;

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
              if (!_sessionActive) return;
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
        'Not updated',
        'Your circle may still think this alert is active.',
      );
    }
  }

  /// Cancels the active SOS and waits for the server to confirm it. Used
  /// before signing out: once signed out the phone can no longer send the
  /// cancel, and an SOS left open alarms caregivers and blocks watch SOS.
  /// Returns false, changing nothing, if the server did not confirm.
  Future<bool> cancelSosAndConfirm() async {
    final AlertDto? current = activeSos.value;
    if (!_sessionActive || current == null) return true;

    final ResultDto<void> result = await FirestoreService.instance()
        .updateAlertStatus(current.id, AlertStatus.cancelled)
        .timeout(
          deliveryGrace,
          onTimeout: () => ResultDto<void>.failure('timed out'),
        );
    if (!result.isSuccess) {
      debugPrint(
        '[SosVM] Could not cancel SOS before sign-out: ${result.error}',
      );
      return false;
    }
    await _clearActiveSos(current);
    return true;
  }

  void _watchOpenSos() {
    try {
      if (!_sessionActive) return;
      _openSosSub = FirestoreService.instance()
          .watchOpenSos(_sessionUid)
          .listen(
            handleOpenSos,
            onError: (Object e) =>
                debugPrint('[SosVM] Error watching open SOS alerts: $e'),
          );
    } catch (e) {
      debugPrint('[SosVM] Could not watch open SOS alerts: $e');
    }
  }

  /// Keeps this phone in step with SOS alerts started or closed elsewhere.
  @visibleForTesting
  void handleOpenSos(List<AlertDto> open) {
    if (!_sessionActive) return;
    final AlertDto? current = activeSos.value;
    final Set<String> openIds = open.map((AlertDto a) => a.id).toSet();

    if (current != null) {
      if (openIds.contains(current.id)) {
        _seenOnServer.add(current.id);
      } else if (_seenOnServer.remove(current.id)) {
        // Cancelled from the watch or another device.
        unawaited(_clearActiveSos(current));
      }
      return;
    }

    final List<AlertDto> candidates =
        open.where((AlertDto a) => !_closedHere.contains(a.id)).toList()..sort(
          (AlertDto a, AlertDto b) => b.createdAt.compareTo(a.createdAt),
        );
    if (candidates.isEmpty) return;

    // Started elsewhere: show it here so it can be followed and cancelled.
    final AlertDto adopted = candidates.first;
    _seenOnServer.add(adopted.id);
    activeSos.value = adopted;
    delivery.value = SosDelivery.delivered;
    try {
      unawaited(_persist(adopted));
      _syncHomeWidget();
      _startElapsed();
      _watchResponses(adopted.id);
      _startNotifyWatchdog(adopted.id);
    } catch (e) {
      debugPrint('[SosVM] Error showing an SOS started elsewhere: $e');
    }
  }

  /// Local side of a cancel: stops timers and listeners, stores the
  /// cancelled alert, and resets the screen.
  Future<void> _clearActiveSos(AlertDto current) async {
    _closedHere.add(current.id);
    _elapsedTimer?.cancel();
    _responsesSub?.cancel();
    _deliveriesSub?.cancel();

    final AlertDto updated = current.copyWith(
      status: AlertStatus.cancelled,
      resolvedAt: DateTime.now(),
    );
    await _persist(updated);
    if (!_sessionActive) return;
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
    _notifyWatchdog?.cancel();
    _notifyGraceElapsed = false;
    delivery.value = SosDelivery.delivered;
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
          (List<AlertDeliveryDto> list) {
            alertDeliveries.value = list;
            reconcileNotified();
          },
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
    if (!_sessionActive || current == null) return;
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
      if (!_sessionActive || alert.userId != _sessionUid) return;
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
    final alertId = activeSos.value?.id;
    if (!_sessionActive || alertId == null) return;
    final result = await FirestoreService.instance().getUser(_uid);
    if (!_sessionActive || activeSos.value?.id != alertId) return;
    final user = result.data;
    if (!result.isSuccess || user?.nearbyAudibleAlert != true) return;
    await Get.find<LocalNotificationsService>().showNearbyEmergencyAlert(
      user?.seizureActionPlan ?? user?.emergencyNote ?? '',
    );
  }

  void _showSnackbar(String title, String message) {
    if (!_sessionActive) return;
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
    if (!_sessionActive) return;
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
