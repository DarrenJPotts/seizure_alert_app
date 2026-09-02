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
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/location_service.dart';
import 'package:seizure_app/features/seizure_log/view_models/seizure_log_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seizure_app/core/constants/firebase_collection_keys.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Whether the alert has actually reached the server.
///
/// Firestore's offline cache acknowledges a write locally and completes the
/// `set()` future only once the *server* has it. Offline that future simply
/// never completes, so the old code sat on an unresolved `await` while the
/// screen showed a live alert — the user believed their circle had been told
/// when nothing had left the phone. That is the worst failure this app has,
/// and it was invisible.
enum SosDelivery {
  /// Written locally, waiting on the server.
  sending,

  /// The server has it. `notifyContacts` has been triggered.
  delivered,

  /// No acknowledgement within [SosViewModel.deliveryGrace]. Almost always no
  /// connection. The alert is queued and will send on reconnect, but nobody
  /// has been told yet and the user needs to know that now.
  queued,

  /// The write was rejected outright.
  failed,
}

class SosViewModel extends GetxController {
  static const _storageKey = 'active_sos';

  /// How long to wait for a server acknowledgement before telling the user the
  /// alert has not gone anywhere. Long enough to ride out a slow mobile
  /// connection, short enough that they can still act on the truth.
  static const Duration deliveryGrace = Duration(seconds: 8);

  final Rxn<AlertDto> activeSos = Rxn<AlertDto>();
  final Rx<Duration> elapsed = Duration.zero.obs;
  final RxList<AlertResponseDto> alertResponses = <AlertResponseDto>[].obs;
  final Rx<SosDelivery> delivery = SosDelivery.delivered.obs;

  Timer? _elapsedTimer;
  Timer? _deliveryWatchdog;
  StreamSubscription<List<AlertResponseDto>>? _responsesSub;

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
    super.onClose();
  }

  /// True while the circle has *not* been told, for whatever reason.
  bool get isUndelivered => delivery.value == SosDelivery.queued || delivery.value == SosDelivery.failed;

  // ─── Restore on app launch ─────────────────────────────────────────────────

  Future<void> _restoreActiveSos() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? json = prefs.getString(_storageKey);
      if (json == null) return;

      final AlertDto dto = AlertDto.fromMap(jsonDecode(json));
      if (dto.status == AlertStatus.sent) {
        activeSos.value = dto;
        _startElapsed();
        _watchResponses(dto.id);
        // Re-issuing the write is idempotent (same deterministic id) and is
        // the only way to learn whether the original one ever landed — the
        // app may have been killed before it did.
        _trackDelivery(dto.id, FirestoreService.instance().createAlert(dto));
      }
    } catch (e) {
      debugPrint('[SosVM] Error restoring active SOS: $e');
    }
  }

  // ─── Start SOS ─────────────────────────────────────────────────────────────

  Future<void> startSos() async {
    try {
      Get.find<SeizureLogViewModel>().addEntry(
        occurredAt: DateTime.now(),
        alertFired: true,
      );

      final DateTime now = DateTime.now();
      final String id = FirebaseFirestore.instance
          .collection(FirebaseCollectionKeys.alerts)
          .doc()
          .id;
      final AlertDto alert = AlertDto(
        id: id,
        userId: _uid,
        type: AlertType.sos,
        status: AlertStatus.sent,
        createdAt: now,
      );

      // Flip to the active screen and notify contacts immediately — do not
      // wait on a GPS fix, which can take several seconds. Location is
      // attached in the background once it resolves.
      await _persist(alert);
      activeSos.value = alert;
      _startElapsed();
      _watchResponses(alert.id);

      _trackDelivery(alert.id, FirestoreService.instance().createAlert(alert));

      final Position? position =
          await LocationService.instance().getCurrentPosition();
      if (position == null) return;
      // The alert may have been cancelled (or a newer one started) while we
      // were waiting on the GPS fix — don't resurrect a stale one.
      if (activeSos.value?.id != alert.id) return;

      final AlertDto located = alert.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      await _persist(located);
      activeSos.value = located;

      unawaited(
        FirestoreService.instance().createAlert(located).then((ResultDto<void> r) {
          if (!r.isSuccess) debugPrint('[SosVM] Error attaching location: ${r.error}');
        }),
      );
    } catch (e) {
      debugPrint('[SosVM] Error starting SOS: $e');
      delivery.value = SosDelivery.failed;
    }
  }

  /// Watches one alert write and reports whether the server ever took it.
  ///
  /// Deliberately not awaited by the caller. Offline the future never
  /// completes, so awaiting it would stall the whole SOS path behind a
  /// network that is not there.
  void _trackDelivery(String alertId, Future<ResultDto<void>> write) {
    delivery.value = SosDelivery.sending;

    _deliveryWatchdog?.cancel();
    _deliveryWatchdog = Timer(deliveryGrace, () {
      if (activeSos.value?.id == alertId && delivery.value == SosDelivery.sending) {
        delivery.value = SosDelivery.queued;
      }
    });

    unawaited(
      write.then((ResultDto<void> result) {
        if (activeSos.value?.id != alertId) return;
        _deliveryWatchdog?.cancel();

        if (result.isSuccess) {
          // Covers the reconnect case too: a queued write completing later
          // flips the banner away on its own.
          delivery.value = SosDelivery.delivered;
        } else {
          debugPrint('[SosVM] Alert write rejected: ${result.error}');
          delivery.value = SosDelivery.failed;
        }
      }),
    );
  }

  // ─── Cancel SOS ────────────────────────────────────────────────────────────

  Future<void> cancelSos() async {
    final AlertDto? current = activeSos.value;
    if (current == null) return;

    try {
      _elapsedTimer?.cancel();
      _responsesSub?.cancel();

      final AlertDto updated = current.copyWith(
        status: AlertStatus.cancelled,
        resolvedAt: DateTime.now(),
      );
      await _persist(updated);
      activeSos.value = null;
      elapsed.value = Duration.zero;
      alertResponses.clear();

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
                _showSnackbar('Alert cancelled', 'Your circle has been told you are OK.');
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
      _showErrorSnackbar('Not Updated', 'Your circle may still think this alert is active.');
    }
  }

  // ─── Alert responses ───────────────────────────────────────────────────────

  void _watchResponses(String alertId) {
    _responsesSub?.cancel();
    _responsesSub = FirestoreService.instance().watchAlertResponses(alertId).listen(
      (List<AlertResponseDto> list) => alertResponses.value = list,
      onError: (Object e) => debugPrint('[SosVM] Error watching responses: $e'),
    );
  }

  // ─── Elapsed timer ─────────────────────────────────────────────────────────

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

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _persist(AlertDto alert) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(alert.toMap()));
    } catch (e) {
      debugPrint('[SosVM] Error persisting active SOS: $e');
      rethrow;
    }
  }

  void _showSnackbar(String title, String message) {
    Get.snackbar(
      '',
      '',
      titleText: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      messageText:
          Text(message, style: const TextStyle(color: Colors.white)),
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
      titleText: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      messageText:
          Text(message, style: const TextStyle(color: Colors.white)),
      snackPosition: SnackPosition.BOTTOM,
      margin: snackbarMargin,
      backgroundColor: Colors.red.shade700,
      borderRadius: Dimensions.eight,
      duration: const Duration(seconds: 4),
    );
  }
}
