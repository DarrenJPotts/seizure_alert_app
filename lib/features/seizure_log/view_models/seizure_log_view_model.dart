import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/seizure_report_service.dart';
import 'package:seizure_app/core/constants/firebase_collection_keys.dart';

class SeizureLogViewModel extends GetxController {
  SeizureLogViewModel(
    this._firestoreService, {
    String? Function()? currentUid,
    SeizureReportService? reportService,
  }) : _currentUid = currentUid,
       _reportService = reportService ?? const SeizureReportService();
  final String? Function()? _currentUid;
  final SeizureReportService _reportService;

  final FirestoreService _firestoreService;

  final RxList<SeizureLogDto> logs = <SeizureLogDto>[].obs;
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;
  final RxBool exporting = false.obs;

  StreamSubscription<List<SeizureLogDto>>? _logsSub;

  String get _uid =>
      (_currentUid == null
          ? FirebaseAuth.instance.currentUser?.uid
          : _currentUid()) ??
      '';

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  void _init() {
    if (_uid.isEmpty) {
      screenState.value = GenericScreenStates.error;
      return;
    }
    screenState.value = GenericScreenStates.loading;
    _logsSub = _firestoreService.watchSeizureLogs(_uid).listen((list) {
      logs.value = list;
      screenState.value = GenericScreenStates.loaded;
    }, onError: (_) => screenState.value = GenericScreenStates.error);
  }

  Future<bool> addEntry({
    required DateTime occurredAt,
    int? durationSeconds,
    String? location,
    String? trigger,
    String? notes,
    String? seizureType,
    String? aura,
    String? severity,
    String? awareness,
    String? injuries,
    int? recoveryMinutes,
    bool rescueMedicationUsed = false,
    bool alertFired = false,
  }) async {
    final log = SeizureLogDto(
      id: _firestoreService.newDocumentId(FirebaseCollectionKeys.seizureLogs),
      userId: _uid,
      occurredAt: occurredAt,
      durationSeconds: durationSeconds,
      location: _clean(location),
      trigger: _clean(trigger),
      notes: _clean(notes),
      seizureType: _clean(seizureType),
      aura: _clean(aura),
      severity: _clean(severity),
      awareness: _clean(awareness),
      injuries: _clean(injuries),
      recoveryMinutes: recoveryMinutes,
      rescueMedicationUsed: rescueMedicationUsed,
      alertFired: alertFired,
    );
    final result = await _firestoreService.addSeizureLog(log);
    return result.isSuccess;
  }

  Future<bool> deleteEntry(String logId) async {
    final result = await _firestoreService.deleteSeizureLog(logId);
    return result.isSuccess;
  }

  Future<String?> shareReport({
    Rect? sharePositionOrigin,
    bool includeCycleData = false,
  }) async {
    if (exporting.value) return null;
    exporting.value = true;
    try {
      final uid = _uid;
      if (uid.isEmpty) return 'Sign in to share your report.';
      final userResult = await _firestoreService.getUser(uid);
      final cycles = includeCycleData
          ? await _firestoreService.getCycleTracking(uid)
          : null;
      if (isClosed || uid != _uid) {
        return 'The account changed. Open your report again.';
      }
      if (includeCycleData &&
          (cycles?.isSuccess != true || cycles?.data?.enabled != true)) {
        return 'Cycle data could not be included. Refresh cycle tracking and try again.';
      }
      final result = await _reportService.shareClinicalReport(
        user: userResult.data,
        logs: List<SeizureLogDto>.from(logs),
        sharePositionOrigin: sharePositionOrigin,
        includeCycleData: includeCycleData,
        cycleEntries: cycles?.data?.entries ?? const [],
      );
      return result.isSuccess ? null : result.error;
    } finally {
      if (!isClosed) exporting.value = false;
    }
  }

  Future<bool> updateEntry({
    required String id,
    required DateTime occurredAt,
    int? durationSeconds,
    String? location,
    String? trigger,
    String? notes,
    String? seizureType,
    String? aura,
    String? severity,
    String? awareness,
    String? injuries,
    int? recoveryMinutes,
    bool rescueMedicationUsed = false,
    bool alertFired = false,
  }) async {
    final log = SeizureLogDto(
      id: id,
      userId: _uid,
      occurredAt: occurredAt,
      durationSeconds: durationSeconds,
      location: _clean(location),
      trigger: _clean(trigger),
      notes: _clean(notes),
      seizureType: _clean(seizureType),
      aura: _clean(aura),
      severity: _clean(severity),
      awareness: _clean(awareness),
      injuries: _clean(injuries),
      recoveryMinutes: recoveryMinutes,
      rescueMedicationUsed: rescueMedicationUsed,
      alertFired: alertFired,
    );
    final result = await _firestoreService.addSeizureLog(log);
    return result.isSuccess;
  }

  String? _clean(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  void onClose() {
    _logsSub?.cancel();
    super.onClose();
  }
}
