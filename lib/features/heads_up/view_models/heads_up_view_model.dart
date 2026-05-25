// lib/features/heads_up/view_models/heads_up_view_model.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/features/heads_up/models/heads_up_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


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
    final dto = HeadsUpDto(
      // id: const Uuid().v4(),
      id:"1",
      createdAt: now,
      expiresAt: now.add(Duration(minutes: selectedMinutes.value)),
      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      status: HeadsUpStatus.active,
    );

    await _persist(dto);
    activeHeadsUp.value = dto;
    _startCountdown();

    // TODO: notify contacts via FCM/SMS
    // await _notificationService.sendHeadsUpAlert(dto);

    isLoading.value = false;
    Get.back(); // close bottom sheet
    _showHeadsUpSnackbar();
  }

  // ─── Check in (cancel) ────────────────────────────────────────────────────

  Future<void> checkIn() async {
    final current = activeHeadsUp.value;
    if (current == null) return;

    _countdownTimer?.cancel();

    final updated = current.copyWith(status: HeadsUpStatus.checkedIn);
    await _persist(updated);
    activeHeadsUp.value = null;
    remaining.value = Duration.zero;
    noteController.clear();

    // TODO: notify contacts they're okay
    // await _notificationService.sendCheckInConfirmation();

    Get.snackbar(
      '',
      '',
      titleText: Text("You're marked safe", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      messageText: Text('Your circle has been notified', style: TextStyle(color: Colors.white)),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black,
      margin: EdgeInsets.all(16),
      borderRadius: 8,
      duration: Duration(seconds: 3),
    );
  }

  // ─── Expiry ────────────────────────────────────────────────────────────────

  Future<void> _onExpired(HeadsUpDto dto) async {
    final updated = dto.copyWith(status: HeadsUpStatus.expired);
    await _persist(updated);
    activeHeadsUp.value = null;
    remaining.value = Duration.zero;

    // TODO: notify contacts to check in on user
    // await _notificationService.sendExpiredHeadsUp(dto);
  }

  // ─── Countdown ────────────────────────────────────────────────────────────

  void _startCountdown() {
    _countdownTimer?.cancel();
    _tick();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (_) => _tick());
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

  void _showHeadsUpSnackbar() {
    Get.snackbar(
      '',
      '',
      titleText: Text('Heads Up sent', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      messageText: Text('Your circle knows to check in on you', style: TextStyle(color: Colors.white)),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black,
      margin: EdgeInsets.all(16),
      borderRadius: 8,
      duration: Duration(seconds: 3),
    );
  }
}