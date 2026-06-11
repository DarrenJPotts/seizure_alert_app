import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';

class AlertHistoryViewModel extends GetxController {
  AlertHistoryViewModel(this._db);

  final FirestoreService _db;
  final alerts = RxList<AlertDto>();
  final screenState = GenericScreenStates.initial.obs;

  StreamSubscription<List<AlertDto>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  void _listen() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    screenState.value = GenericScreenStates.loading;
    _sub = _db.watchRecentAlerts(uid).listen(
      (list) {
        alerts.value = list;
        screenState.value =
            list.isEmpty ? GenericScreenStates.empty : GenericScreenStates.loaded;
      },
      onError: (_) => screenState.value = GenericScreenStates.error,
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}

class AlertHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AlertHistoryViewModel(FirestoreService.instance()));
  }
}
