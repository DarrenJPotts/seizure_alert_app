import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/core/services/caregiver_service.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';

class AlertHistoryViewModel extends GetxController {
  AlertHistoryViewModel(this._db, this._caregiverService, this._appMode);

  final FirestoreService _db;
  final CaregiverService _caregiverService;
  final AppModeService _appMode;
  final alerts = RxList<AlertDto>();
  final screenState = GenericScreenStates.initial.obs;

  StreamSubscription<List<AlertDto>>? _sub;
  Worker? _modeWorker;

  bool get caregiverMode => _appMode.caregiverMode.value;

  @override
  void onInit() {
    super.onInit();
    _modeWorker = ever<bool>(_appMode.caregiverMode, _startForMode);
    _startForMode(caregiverMode);
  }

  void _startForMode(bool caregiver) {
    _sub?.cancel();
    _sub = null;
    alerts.clear();

    if (caregiver) {
      unawaited(_loadCaregiverAlerts());
    } else {
      _listenToOwnAlerts();
    }
  }

  void _listenToOwnAlerts() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    screenState.value = GenericScreenStates.loading;
    _sub = _db.watchRecentAlerts(uid).listen((list) {
      alerts.value = list;
      screenState.value = list.isEmpty
          ? GenericScreenStates.empty
          : GenericScreenStates.loaded;
    }, onError: (_) => screenState.value = GenericScreenStates.error);
  }

  Future<void> _loadCaregiverAlerts() async {
    screenState.value = GenericScreenStates.loading;
    final result = await _caregiverService.getAlertHistory();
    if (!caregiverMode) return;
    if (!result.isSuccess || result.data == null) {
      screenState.value = GenericScreenStates.error;
      return;
    }

    alerts.assignAll(result.data!);
    screenState.value = alerts.isEmpty
        ? GenericScreenStates.empty
        : GenericScreenStates.loaded;
  }

  Future<void> reload() async {
    if (caregiverMode) await _loadCaregiverAlerts();
  }

  @override
  void onClose() {
    _sub?.cancel();
    _modeWorker?.dispose();
    super.onClose();
  }
}

class AlertHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AlertHistoryViewModel(
        FirestoreService.instance(),
        CaregiverService.instance(),
        AppModeService.instance(),
      ),
      fenix: true,
    );
  }
}
