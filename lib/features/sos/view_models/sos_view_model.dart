import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/location_service.dart';
import 'package:seizure_app/features/seizure_log/view_models/seizure_log_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SosViewModel extends GetxController {
  static const _storageKey = 'active_sos';

  final Rxn<AlertDto> activeSos = Rxn<AlertDto>();
  final Rx<Duration> elapsed = Duration.zero.obs;

  Timer? _elapsedTimer;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _restoreActiveSos();
  }

  @override
  void onClose() {
    _elapsedTimer?.cancel();
    super.onClose();
  }

  // ─── Restore on app launch ─────────────────────────────────────────────────

  Future<void> _restoreActiveSos() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json == null) return;

    final dto = AlertDto.fromMap(jsonDecode(json));
    if (dto.status == AlertStatus.sent) {
      activeSos.value = dto;
      _startElapsed();
    }
  }

  // ─── Start SOS ─────────────────────────────────────────────────────────────

  Future<void> startSos() async {
    Get.find<SeizureLogViewModel>().addEntry(
      occurredAt: DateTime.now(),
      alertFired: true,
    );

    final position = await LocationService.instance().getCurrentPosition();

    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final alert = AlertDto(
      id: id,
      userId: _uid,
      type: AlertType.sos,
      status: AlertStatus.sent,
      latitude: position?.latitude,
      longitude: position?.longitude,
      createdAt: now,
    );

    await _persist(alert);
    activeSos.value = alert;
    _startElapsed();

    await FirestoreService.instance().createAlert(alert);

    _showSnackbar('Alert Sent', 'Your circle has been notified');
  }

  // ─── Cancel SOS ────────────────────────────────────────────────────────────

  Future<void> cancelSos() async {
    final current = activeSos.value;
    if (current == null) return;

    _elapsedTimer?.cancel();

    final updated = current.copyWith(
      status: AlertStatus.cancelled,
      resolvedAt: DateTime.now(),
    );
    await _persist(updated);
    activeSos.value = null;
    elapsed.value = Duration.zero;

    await FirestoreService.instance().updateAlertStatus(
      current.id,
      AlertStatus.cancelled,
    );

    _showSnackbar('Alert Cancelled', 'Your circle has been notified');
  }

  // ─── Elapsed timer ─────────────────────────────────────────────────────────

  void _startElapsed() {
    _elapsedTimer?.cancel();
    _tick();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final current = activeSos.value;
    if (current == null) return;
    elapsed.value = DateTime.now().difference(current.createdAt);
  }

  String formattedElapsed() {
    final d = elapsed.value;
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _persist(AlertDto alert) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(alert.toMap()));
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
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }
}
