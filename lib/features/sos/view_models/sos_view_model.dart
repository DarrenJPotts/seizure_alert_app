import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/dtos/alert_response_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/location_service.dart';
import 'package:seizure_app/features/seizure_log/view_models/seizure_log_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SosViewModel extends GetxController {
  static const _storageKey = 'active_sos';

  final Rxn<AlertDto> activeSos = Rxn<AlertDto>();
  final Rx<Duration> elapsed = Duration.zero.obs;
  final RxList<AlertResponseDto> alertResponses = <AlertResponseDto>[].obs;

  Timer? _elapsedTimer;
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
    _responsesSub?.cancel();
    super.onClose();
  }

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
      final String id = now.millisecondsSinceEpoch.toString();
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

      final ResultDto<void> result =
          await FirestoreService.instance().createAlert(alert);
      if (result.isSuccess) {
        _showSnackbar('Alert Sent', 'Your circle has been notified');
      } else {
        debugPrint('[SosVM] Error creating alert: ${result.error}');
        _showErrorSnackbar(
            'Alert Not Sent', 'Call your emergency contacts directly.');
        return;
      }

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

      final ResultDto<void> locationResult =
          await FirestoreService.instance().createAlert(located);
      if (!locationResult.isSuccess) {
        debugPrint(
            '[SosVM] Error attaching location: ${locationResult.error}');
      }
    } catch (e) {
      debugPrint('[SosVM] Error starting SOS: $e');
      _showErrorSnackbar(
          'Alert Not Sent', 'Call your emergency contacts directly.');
    }
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

      final ResultDto<void> result =
          await FirestoreService.instance().updateAlertStatus(
        current.id,
        AlertStatus.cancelled,
      );
      if (result.isSuccess) {
        _showSnackbar('Alert Cancelled', 'Your circle has been notified');
      } else {
        debugPrint('[SosVM] Error cancelling alert: ${result.error}');
        _showErrorSnackbar('Not Updated', 'Your circle may still think this alert is active.');
      }
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
      backgroundColor: Colors.black,
      margin: EdgeInsets.all(Dimensions.sixteen),
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
      backgroundColor: Colors.red.shade700,
      margin: EdgeInsets.all(Dimensions.sixteen),
      borderRadius: Dimensions.eight,
      duration: const Duration(seconds: 4),
    );
  }
}
