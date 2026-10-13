import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/constants/snackbar_margin.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/location_service.dart';
import 'package:seizure_app/core/services/home_widget_service.dart';
import 'package:seizure_app/core/dtos/heads_up_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seizure_app/core/constants/firebase_collection_keys.dart';

enum HeadsUpDelivery { unknown, sending, delivered, queued, failed }

class HeadsUpViewModel extends GetxController {
  HeadsUpViewModel({String? Function()? currentUid}) : _currentUid = currentUid;
  final String? Function()? _currentUid;

  static HeadsUpViewModel instance() => Get.find<HeadsUpViewModel>();

  static const String _storageKey = 'active_heads_up';

  final Rxn<HeadsUpDto> activeHeadsUp = Rxn<HeadsUpDto>();
  final Rx<Duration> remaining = Duration.zero.obs;
  final RxBool isLoading = false.obs;
  final Rx<HeadsUpDelivery> delivery = HeadsUpDelivery.unknown.obs;

  final TextEditingController noteController = TextEditingController();
  final RxInt selectedMinutes = 60.obs;

  static const List<int> windowOptions = [30, 60, 120];
  static const int maxDurationMinutes = 24 * 60;
  static bool isValidDuration(int minutes) =>
      minutes >= 1 && minutes <= maxDurationMinutes;

  Timer? _countdownTimer;
  Timer? _deliveryWatchdog;
  String? _deliveryHeadsUpId;

  static const Duration deliveryGrace = Duration(seconds: 8);

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
    _restoreActiveHeadsUp();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _deliveryWatchdog?.cancel();
    noteController.dispose();
    super.onClose();
  }

  Future<void> _restoreActiveHeadsUp() async {
    try {
      if (!_sessionActive) return;
      final prefs = await SharedPreferences.getInstance();
      if (!_sessionActive) return;
      final json = prefs.getString(_storageKey);
      if (json == null) return;

      final dto = HeadsUpDto.fromMap(jsonDecode(json));
      if (dto.userId != _sessionUid) return;

      if (dto.isActive) {
        activeHeadsUp.value = dto;
        _syncHomeWidget();
        _startCountdown();
        _retryActiveHeadsUp(dto);
      } else if (dto.status == HeadsUpStatus.active) {
        await _onExpired(dto);
      } else if (dto.status == HeadsUpStatus.cancelled ||
          dto.status == HeadsUpStatus.checkedIn) {
        unawaited(_retryTerminalStatus(dto));
      }
    } catch (e) {
      debugPrint('[HeadsUpVM] Error restoring active Heads Up: $e');
    }
  }

  void _retryActiveHeadsUp(HeadsUpDto dto) {
    final AlertDto alert = AlertDto(
      id: '${dto.id}_alert',
      userId: dto.userId,
      type: AlertType.headsUp,
      status: AlertStatus.sent,
      message: dto.note,
      createdAt: dto.createdAt,
    );
    final FirestoreService firestoreService = FirestoreService.instance();
    _trackDelivery(
      dto.id,
      Future.wait(<Future<ResultDto<void>>>[
        firestoreService.upsertHeadsUp(dto),
        firestoreService.createAlert(alert),
      ]),
    );
  }

  Future<void> _retryTerminalStatus(HeadsUpDto dto) async {
    final AlertStatus alertStatus = dto.status == HeadsUpStatus.cancelled
        ? AlertStatus.cancelled
        : AlertStatus.resolved;
    final FirestoreService firestoreService = FirestoreService.instance();
    await Future.wait(<Future<ResultDto<void>>>[
      firestoreService.upsertHeadsUp(dto),
      if (dto.userId.isNotEmpty)
        firestoreService.updateAlertStatus('${dto.id}_alert', alertStatus),
    ]);
  }

  Future<void> startHeadsUp() async {
    if (!_sessionActive || isLoading.value || activeHeadsUp.value != null) {
      return;
    }
    if (!isValidDuration(selectedMinutes.value)) {
      _showErrorSnackbar('Invalid duration', 'Enter 1 to 1,440 minutes.');
      return;
    }
    isLoading.value = true;

    try {
      final now = DateTime.now();
      final firestoreService = FirestoreService.instance();
      final id = firestoreService.newDocumentId(FirebaseCollectionKeys.headsUp);
      final dto = HeadsUpDto(
        id: id,
        userId: _uid,
        createdAt: now,
        expiresAt: now.add(Duration(minutes: selectedMinutes.value)),
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
        status: HeadsUpStatus.active,
      );
      final AlertDto alert = AlertDto(
        id: '${id}_alert',
        userId: _uid,
        type: AlertType.headsUp,
        status: AlertStatus.sent,
        message: dto.note,
        createdAt: now,
      );
      await _persist(dto);
      if (!_sessionActive) return;
      activeHeadsUp.value = dto;
      _syncHomeWidget();
      _startCountdown();
      final Future<List<ResultDto<void>>> writes = Future.wait([
        firestoreService.upsertHeadsUp(dto),
        firestoreService.createAlert(alert),
      ]);
      _trackDelivery(id, writes);
      unawaited(_attachLocation(id, alert));
      Get.back();

      try {
        final List<ResultDto<void>> results = await writes.timeout(
          deliveryGrace,
        );
        if (results.every((ResultDto<void> result) => result.isSuccess)) {
          _showSnackbar(
            'Heads Up sent',
            'The alert reached the server. Push notifications may take a moment.',
          );
        } else {
          _showErrorSnackbar(
            'Heads Up not confirmed',
            'At least one part did not save. Check your circle before relying on this alert.',
          );
        }
      } on TimeoutException {
        _showSnackbar(
          'Heads Up queued',
          'The server has not confirmed both updates. Check with your circle once you reconnect.',
        );
      }
    } catch (e) {
      debugPrint('[HeadsUpVM] Error starting Heads Up: $e');
      _showErrorSnackbar(
        'Heads Up Not Sent',
        'Check your connection and try again.',
      );
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void _trackDelivery(String id, Future<List<ResultDto<void>>> writes) {
    _deliveryHeadsUpId = id;
    delivery.value = HeadsUpDelivery.sending;
    _deliveryWatchdog?.cancel();
    _deliveryWatchdog = Timer(deliveryGrace, () {
      if (_deliveryHeadsUpId == id &&
          delivery.value == HeadsUpDelivery.sending) {
        delivery.value = HeadsUpDelivery.queued;
      }
    });

    unawaited(
      writes.then((List<ResultDto<void>> results) {
        if (!_sessionActive || _deliveryHeadsUpId != id) return;
        _deliveryWatchdog?.cancel();
        delivery.value =
            results.every((ResultDto<void> result) => result.isSuccess)
            ? HeadsUpDelivery.delivered
            : HeadsUpDelivery.failed;
      }),
    );
  }

  Future<void> _attachLocation(String headsUpId, AlertDto alert) async {
    try {
      final Position? position = await LocationService.instance()
          .getCurrentPosition();
      if (!_sessionActive ||
          position == null ||
          activeHeadsUp.value?.id != headsUpId) {
        return;
      }

      final AlertDto located = alert.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final ResultDto<void> result = await FirestoreService.instance()
          .createAlert(located);
      if (!result.isSuccess) {
        debugPrint('[HeadsUpVM] Error attaching location: ${result.error}');
      }
    } catch (error) {
      debugPrint('[HeadsUpVM] Error attaching location: $error');
    }
  }

  Future<void> cancelHeadsUp() async {
    final current = activeHeadsUp.value;
    if (!_sessionActive || current == null) return;

    try {
      _countdownTimer?.cancel();

      final updated = current.copyWith(status: HeadsUpStatus.cancelled);
      await _persist(updated);
      if (!_sessionActive) return;
      activeHeadsUp.value = null;
      _syncHomeWidget();
      remaining.value = Duration.zero;
      noteController.clear();

      unawaited(
        _syncStatusChange(
          updated,
          AlertStatus.cancelled,
          successTitle: 'Heads Up cancelled',
        ),
      );
    } catch (e) {
      debugPrint('[HeadsUpVM] Error cancelling Heads Up: $e');
      _showErrorSnackbar(
        'Not Updated',
        'Your circle may still think this is active.',
      );
    }
  }

  Future<void> checkIn() async {
    final current = activeHeadsUp.value;
    if (!_sessionActive || current == null) return;

    try {
      _countdownTimer?.cancel();

      final updated = current.copyWith(status: HeadsUpStatus.checkedIn);
      await _persist(updated);
      if (!_sessionActive) return;
      activeHeadsUp.value = null;
      _syncHomeWidget();
      remaining.value = Duration.zero;
      noteController.clear();

      unawaited(
        _syncStatusChange(
          updated,
          AlertStatus.resolved,
          successTitle: "You're marked safe",
        ),
      );
    } catch (e) {
      debugPrint('[HeadsUpVM] Error checking in: $e');
      _showErrorSnackbar(
        'Not Updated',
        'Your circle may still think this is active.',
      );
    }
  }

  Future<void> _syncStatusChange(
    HeadsUpDto updated,
    AlertStatus alertStatus, {
    required String successTitle,
  }) async {
    final FirestoreService firestoreService = FirestoreService.instance();
    final Future<List<ResultDto<void>>> writes = Future.wait([
      firestoreService.upsertHeadsUp(updated),
      if (_uid.isNotEmpty)
        firestoreService.updateAlertStatus('${updated.id}_alert', alertStatus),
    ]);

    try {
      final List<ResultDto<void>> results = await writes.timeout(deliveryGrace);
      if (results.every((ResultDto<void> result) => result.isSuccess)) {
        _showSnackbar(successTitle, 'The update reached the server.');
      } else {
        _showErrorSnackbar(
          'Update not sent',
          'Your circle may still see the previous status.',
        );
      }
    } on TimeoutException {
      _showSnackbar(
        'Update queued',
        'Saved on this phone. It will sync when you reconnect; your circle may still see the previous status.',
      );
    } catch (error) {
      debugPrint('[HeadsUpVM] Error syncing status: $error');
      _showErrorSnackbar(
        'Update not confirmed',
        'Your circle may still see the previous status.',
      );
    }
  }

  /// Escalation is owned by the delayed server task created with the Heads Up
  /// document, so it still runs when the app is closed. The client only clears
  /// its local state to avoid racing the task and stranding an alert.
  Future<void> _onExpired(HeadsUpDto dto) async {
    try {
      await _persist(dto.copyWith(status: HeadsUpStatus.expired));
      if (!_sessionActive) return;
      activeHeadsUp.value = null;
      _syncHomeWidget();
      remaining.value = Duration.zero;
    } catch (e) {
      debugPrint('[HeadsUpVM] Error handling Heads Up expiry: $e');
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _tick();
    if (!_sessionActive || activeHeadsUp.value == null) return;
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tick(),
    );
  }

  void _tick() {
    final current = activeHeadsUp.value;
    if (!_sessionActive || current == null) return;

    final left = current.expiresAt.difference(DateTime.now());

    if (left.isNegative) {
      _countdownTimer?.cancel();
      _onExpired(current);
    } else {
      remaining.value = left;
    }
  }

  Future<void> _persist(HeadsUpDto dto) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_sessionActive || dto.userId != _sessionUid) return;
      await prefs.setString(_storageKey, jsonEncode(dto.toMap()));
    } catch (e) {
      debugPrint('[HeadsUpVM] Error persisting active Heads Up: $e');
      rethrow;
    }
  }

  void _syncHomeWidget() {
    if (Get.isRegistered<HomeWidgetService>()) {
      unawaited(Get.find<HomeWidgetService>().syncCurrentState());
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
