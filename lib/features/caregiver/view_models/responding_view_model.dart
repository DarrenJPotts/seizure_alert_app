import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/constants/snackbar_margin.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/dtos/alert_detail_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/call_service.dart';
import 'package:seizure_app/core/services/caregiver_service.dart';
import 'package:seizure_app/core/services/firebase_messaging_service.dart';

class RespondingViewModel extends GetxController {
  RespondingViewModel(this._alertId, this._caregiverService);

  static const Duration _pollInterval = Duration(seconds: 30);

  static const int maxNoteLength = 2000;

  final String _alertId;
  final CaregiverService _caregiverService;

  final Rxn<AlertDetailDto> detail = Rxn<AlertDetailDto>();
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;
  final Rx<Duration> elapsed = Duration.zero.obs;
  final RxBool isSavingNote = false.obs;
  final RxSet<String> nudging = <String>{}.obs;

  Timer? _ticker;
  Timer? _poll;
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
    unawaited(_load(initial: true));
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _poll?.cancel();
    _notificationWorker?.dispose();
    super.onClose();
  }

  void _handleNotification(RemoteMessage? message) {
    if (message == null || message.data['alertId'] != _alertId) return;
    if (message.data['alertStatus'] == AlertStatus.sent.name) return;
    unawaited(_load());
  }

  Future<void> _load({bool initial = false}) async {
    if (initial) screenState.value = GenericScreenStates.loading;

    final result = await _caregiverService.getAlertDetail(_alertId);
    if (!result.isSuccess || result.data == null) {
      if (initial) screenState.value = GenericScreenStates.error;
      return;
    }

    detail.value = result.data;
    screenState.value = GenericScreenStates.loaded;

    if (!isAlertActive) {
      _ticker?.cancel();
      _ticker = null;
      _poll?.cancel();
      _poll = null;
      return;
    }

    if (initial) {
      _startTicker();
      _poll = Timer.periodic(_pollInterval, (_) => _load());
    }
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

  Future<void> reload() => _load();

  String get elapsedClock {
    final Duration since = elapsed.value;
    final String mm = since.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String ss = since.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (since.inHours > 0) return '${since.inHours}:$mm:$ss';
    return '$mm:$ss';
  }

  bool get isAlertActive => detail.value?.alert.status == AlertStatus.sent;

  String get alertStatusLabel => switch (detail.value?.alert.status) {
    AlertStatus.cancelled => 'CANCELLED',
    AlertStatus.resolved => 'RESOLVED',
    _ => 'ACTIVE $elapsedClock',
  };

  String get ownerName => detail.value?.ownerProfile.displayName ?? '';

  String get subtitle {
    final AlertDetailDto? current = detail.value;
    if (current == null) return '';

    final DateTime? respondedAt = current.callerResponse?.respondedAt;
    final int notified = current.notifiedCount;
    final String people = notified == 1
        ? '1 caregiver notified'
        : '$notified caregivers notified';

    if (respondedAt == null) return people;
    final String hhmm =
        '${respondedAt.hour.toString().padLeft(2, '0')}:${respondedAt.minute.toString().padLeft(2, '0')}';
    return 'You responded at $hhmm · $people';
  }

  List<AlertResponderDto> get roster {
    final AlertDetailDto? current = detail.value;
    if (current == null) return const <AlertResponderDto>[];
    return <AlertResponderDto>[
      if (current.callerResponse != null) current.callerResponse!,
      ...current.otherResponders,
    ];
  }

  String statusFor(AlertResponderDto responder) {
    if (responder.responding) {
      return responder.isCaller ? 'On my way' : 'On their way';
    }
    if (responder.seen) {
      final DateTime? seenAt = responder.seenAt;
      if (seenAt == null) return 'Seen the alert';
      return 'Seen at ${seenAt.hour.toString().padLeft(2, '0')}:${seenAt.minute.toString().padLeft(2, '0')}';
    }
    return 'Notified, no response yet';
  }

  bool canNudge(AlertResponderDto responder) =>
      isAlertActive &&
      !responder.isCaller &&
      !responder.responding &&
      responder.responderId != null;

  List<String> get carePlanSteps =>
      detail.value?.ownerProfile.carePlanSteps ?? const <String>[];

  Future<void> callOwner() =>
      CallService.call(detail.value?.ownerProfile.phone);

  Future<void> nudge(AlertResponderDto responder) async {
    final String? targetId = responder.responderId;
    if (targetId == null || nudging.contains(targetId)) return;

    nudging.add(targetId);
    final result = await _caregiverService.nudgeResponder(
      alertId: _alertId,
      targetResponderId: targetId,
    );
    nudging.remove(targetId);

    if (!result.isSuccess) {
      _notify(
        'Could not nudge',
        'Try phoning ${responder.contactName} instead.',
      );
      return;
    }
    if (result.data == false) {
      _notify(
        'Nudge not delivered',
        '${responder.contactName} has no device registered for alerts. Phone them.',
      );
      return;
    }
    _notify(
      'Nudge sent',
      '${responder.contactName} has been asked to respond.',
    );
  }

  Future<bool> saveNote(String note) async {
    final AlertDetailDto? current = detail.value;
    final String trimmed = note.trim();
    if (current == null || trimmed.isEmpty || isSavingNote.value) return false;

    if (trimmed.length > maxNoteLength) {
      _notify('Too long', 'Keep your note under $maxNoteLength characters.');
      return false;
    }

    isSavingNote.value = true;
    final result = await _caregiverService.submitAlertResponse(
      alertId: current.alert.id,
      note: trimmed,
    );
    isSavingNote.value = false;

    if (!result.isSuccess) {
      _notify('Could not save', 'Your note was not recorded. Try again.');
      return false;
    }
    _notify('Saved', 'Your account of what happened was recorded.');
    unawaited(_load());
    return true;
  }

  /// No BuildContext here, so the scheme comes from `Get.theme`. A snackbar is
  /// an inverted surface in Material 3 — the same pair `snackBarTheme` uses for
  /// the framework's own snackbars, which `Get.snackbar` bypasses.
  void _notify(String title, String message) {
    final ColorScheme scheme = Get.theme.colorScheme;

    Get.snackbar(
      '',
      '',
      titleText: Text(
        title,
        style: TextStyle(
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(color: scheme.onInverseSurface),
      ),
      snackPosition: SnackPosition.BOTTOM,
      margin: snackbarMargin,
      backgroundColor: scheme.inverseSurface,
      borderRadius: Dimensions.eight,
      duration: const Duration(seconds: 4),
    );
  }
}

class RespondingBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as Map?;
    final alertId =
        (args?['alertId'] as String?) ?? Get.parameters['alertId'] ?? '';
    Get.lazyPut(
      () => RespondingViewModel(alertId, CaregiverService.instance()),
    );
  }
}
