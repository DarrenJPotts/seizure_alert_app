// lib/features/heads_up/view_models/heads_up_view_model.dart

import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/location_service.dart';
import 'package:seizure_app/features/heads_up/models/heads_up_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';


class HeadsUpViewModel extends GetxController {
  HeadsUpViewModel();

  static HeadsUpViewModel instance() => Get.isRegistered<HeadsUpViewModel>()
      ? Get.find<HeadsUpViewModel>()
      : Get.put<HeadsUpViewModel>(HeadsUpViewModel());

  static const String _storageKey = 'active_heads_up';

  final Rxn<HeadsUpDto> activeHeadsUp = Rxn<HeadsUpDto>();
  final Rx<Duration> remaining = Duration.zero.obs;
  final RxBool isLoading = false.obs;

  final TextEditingController noteController = TextEditingController();
  final RxInt selectedMinutes = 60.obs;

  static const List<int> windowOptions = [30, 60, 120];

  Timer? _countdownTimer;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _restoreActiveHeadsUp();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    noteController.dispose();
    super.onClose();
  }

  // ─── Restore on app launch ─────────────────────────────────────────────────

  Future<void> _restoreActiveHeadsUp() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json == null) return;

    final dto = HeadsUpDto.fromMap(jsonDecode(json));

    if (dto.isActive) {
      activeHeadsUp.value = dto;
      _startCountdown();
    } else if (dto.status == HeadsUpStatus.active) {
      // Timer expired while app was closed
      await _onExpired(dto);
    }
  }

  // ─── Create ────────────────────────────────────────────────────────────────

  Future<void> startHeadsUp() async {
    isLoading.value = true;

    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final dto = HeadsUpDto(
      id: id,
      userId: _uid,
      createdAt: now,
      expiresAt: now.add(Duration(minutes: selectedMinutes.value)),
      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      status: HeadsUpStatus.active,
    );

    await _persist(dto);
    activeHeadsUp.value = dto;
    _startCountdown();

    final position = await LocationService.instance().getCurrentPosition();

    // Save to Firestore so contacts can be notified
    final firestoreService = FirestoreService.instance();
    await firestoreService.upsertHeadsUp(dto);

    // Create an alert record for contact notification tracking
    if (_uid.isNotEmpty) {
      final alert = AlertDto(
        id: '${id}_alert',
        userId: _uid,
        type: AlertType.headsUp,
        status: AlertStatus.sent,
        latitude: position?.latitude,
        longitude: position?.longitude,
        message: dto.note,
        createdAt: now,
      );
      await firestoreService.createAlert(alert);
    }

    isLoading.value = false;
    Get.back(); // close bottom sheet
    _showSnackbar('Heads Up sent', 'Your circle knows to check in on you');
  }

  // ─── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancelHeadsUp() async {
    final current = activeHeadsUp.value;
    if (current == null) return;

    _countdownTimer?.cancel();

    final updated = current.copyWith(status: HeadsUpStatus.cancelled);
    await _persist(updated);
    activeHeadsUp.value = null;
    remaining.value = Duration.zero;
    noteController.clear();

    final firestoreService = FirestoreService.instance();
    await firestoreService.upsertHeadsUp(updated);

    if (_uid.isNotEmpty) {
      await firestoreService.updateAlertStatus(
        '${current.id}_alert',
        AlertStatus.cancelled,
      );
    }

    _showSnackbar('Heads Up cancelled', 'Your circle has been notified');
  }

  // ─── Check in ─────────────────────────────────────────────────────────────

  Future<void> checkIn() async {
    final current = activeHeadsUp.value;
    if (current == null) return;

    _countdownTimer?.cancel();

    final updated = current.copyWith(status: HeadsUpStatus.checkedIn);
    await _persist(updated);
    activeHeadsUp.value = null;
    remaining.value = Duration.zero;
    noteController.clear();

    final firestoreService = FirestoreService.instance();
    await firestoreService.upsertHeadsUp(updated);

    if (_uid.isNotEmpty) {
      await firestoreService.updateAlertStatus(
        '${current.id}_alert',
        AlertStatus.resolved,
      );
    }

    _showSnackbar("You're marked safe", 'Your circle has been notified');
  }

  // ─── Expiry ────────────────────────────────────────────────────────────────

  Future<void> _onExpired(HeadsUpDto dto) async {
    final updated = dto.copyWith(status: HeadsUpStatus.expired);
    await _persist(updated);
    activeHeadsUp.value = null;
    remaining.value = Duration.zero;

    final firestoreService = FirestoreService.instance();
    await firestoreService.upsertHeadsUp(updated);

    if (_uid.isNotEmpty) {
      final alert = AlertDto(
        id: '${dto.id}_expired',
        userId: _uid,
        type: AlertType.headsUpExpired,
        status: AlertStatus.sent,
        message: dto.note,
        createdAt: DateTime.now(),
      );
      await firestoreService.createAlert(alert);
    }
  }

  // ─── Countdown ────────────────────────────────────────────────────────────

  void _startCountdown() {
    _countdownTimer?.cancel();
    _tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final current = activeHeadsUp.value;
    if (current == null) return;

    final left = current.expiresAt.difference(DateTime.now());

    if (left.isNegative) {
      _countdownTimer?.cancel();
      _onExpired(current);
    } else {
      remaining.value = left;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _persist(HeadsUpDto dto) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(dto.toMap()));
  }

  String formattedRemaining() {
    final d = remaining.value;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void _showSnackbar(String title, String message) {
    Get.snackbar(
      '',
      '',
      titleText: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      messageText: Text(message, style: const TextStyle(color: Colors.white)),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }
}
