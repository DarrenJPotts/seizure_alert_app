// lib/features/heads_up/view_models/heads_up_view_model.dart

import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/location_service.dart';
import 'package:seizure_app/core/dtos/heads_up_dto.dart';
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
    try {
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
    } catch (e) {
      debugPrint('[HeadsUpVM] Error restoring active Heads Up: $e');
    }
  }

  // ─── Create ────────────────────────────────────────────────────────────────

  Future<void> startHeadsUp() async {
    isLoading.value = true;

    try {
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
      final headsUpResult = await firestoreService.upsertHeadsUp(dto);

      var alertOk = true;
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
        final alertResult = await firestoreService.createAlert(alert);
        alertOk = alertResult.isSuccess;
        if (!alertOk) debugPrint('[HeadsUpVM] Error creating alert: ${alertResult.error}');
      }

      Get.back(); // close bottom sheet
      if (headsUpResult.isSuccess && alertOk) {
        _showSnackbar('Heads Up sent', 'Your circle knows to check in on you');
      } else {
        if (!headsUpResult.isSuccess) {
          debugPrint('[HeadsUpVM] Error saving Heads Up: ${headsUpResult.error}');
        }
        _showErrorSnackbar('Heads Up Not Sent', 'Check your connection and try again.');
      }
    } catch (e) {
      debugPrint('[HeadsUpVM] Error starting Heads Up: $e');
      _showErrorSnackbar('Heads Up Not Sent', 'Check your connection and try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancelHeadsUp() async {
    final current = activeHeadsUp.value;
    if (current == null) return;

    try {
      _countdownTimer?.cancel();

      final updated = current.copyWith(status: HeadsUpStatus.cancelled);
      await _persist(updated);
      activeHeadsUp.value = null;
      remaining.value = Duration.zero;
      noteController.clear();

      final firestoreService = FirestoreService.instance();
      final result = await firestoreService.upsertHeadsUp(updated);

      if (_uid.isNotEmpty) {
        await firestoreService.updateAlertStatus(
          '${current.id}_alert',
          AlertStatus.cancelled,
        );
      }

      if (result.isSuccess) {
        _showSnackbar('Heads Up cancelled', 'Your circle has been notified');
      } else {
        debugPrint('[HeadsUpVM] Error cancelling Heads Up: ${result.error}');
        _showErrorSnackbar('Not Updated', 'Your circle may still think this is active.');
      }
    } catch (e) {
      debugPrint('[HeadsUpVM] Error cancelling Heads Up: $e');
      _showErrorSnackbar('Not Updated', 'Your circle may still think this is active.');
    }
  }

  // ─── Check in ─────────────────────────────────────────────────────────────

  Future<void> checkIn() async {
    final current = activeHeadsUp.value;
    if (current == null) return;

    try {
      _countdownTimer?.cancel();

      final updated = current.copyWith(status: HeadsUpStatus.checkedIn);
      await _persist(updated);
      activeHeadsUp.value = null;
      remaining.value = Duration.zero;
      noteController.clear();

      final firestoreService = FirestoreService.instance();
      final result = await firestoreService.upsertHeadsUp(updated);

      if (_uid.isNotEmpty) {
        await firestoreService.updateAlertStatus(
          '${current.id}_alert',
          AlertStatus.resolved,
        );
      }

      if (result.isSuccess) {
        _showSnackbar("You're marked safe", 'Your circle has been notified');
      } else {
        debugPrint('[HeadsUpVM] Error checking in: ${result.error}');
        _showErrorSnackbar('Not Updated', 'Your circle may still think this is active.');
      }
    } catch (e) {
      debugPrint('[HeadsUpVM] Error checking in: $e');
      _showErrorSnackbar('Not Updated', 'Your circle may still think this is active.');
    }
  }

  // ─── Expiry ────────────────────────────────────────────────────────────────

  /// Clears the local countdown once the window has run out.
  ///
  /// Escalation itself — flipping the Firestore `headsUp` document to
  /// `expired` and creating the `headsUpExpired` alert that notifies the
  /// contact circle — is deliberately *not* done here. It belongs to the
  /// `expireHeadsUpWindows` sweep in `functions/index.js`, because the whole
  /// point of a Heads Up is to cover the case where this app is not running.
  /// If the client escalated too, the two would race: writing `expired` from
  /// here would take the document out of the sweep's `status == active` query
  /// and could strand it without an alert ever being sent.
  ///
  /// The trade-off is up to a minute of latency on a window the user chose to
  /// be 30 minutes or longer, in exchange for the escalation being guaranteed
  /// rather than best-effort.
  Future<void> _onExpired(HeadsUpDto dto) async {
    try {
      await _persist(dto.copyWith(status: HeadsUpStatus.expired));
      activeHeadsUp.value = null;
      remaining.value = Duration.zero;
    } catch (e) {
      debugPrint('[HeadsUpVM] Error handling Heads Up expiry: $e');
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
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(dto.toMap()));
    } catch (e) {
      debugPrint('[HeadsUpVM] Error persisting active Heads Up: $e');
      rethrow;
    }
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
      margin: EdgeInsets.all(Dimensions.sixteen),
      borderRadius: Dimensions.eight,
      duration: const Duration(seconds: 3),
    );
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      '',
      '',
      titleText: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      messageText: Text(message, style: const TextStyle(color: Colors.white)),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      margin: EdgeInsets.all(Dimensions.sixteen),
      borderRadius: Dimensions.eight,
      duration: const Duration(seconds: 4),
    );
  }
}
