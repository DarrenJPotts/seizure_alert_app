import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/constants/firebase_collection_keys.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeizureLogViewModel extends GetxController {
  SeizureLogViewModel(this._firestoreService);

  final FirestoreService _firestoreService;

  // ─── State ────────────────────────────────────────────────────────────────

  final RxList<SeizureLogDto> logs = <SeizureLogDto>[].obs;
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;

  StreamSubscription<List<SeizureLogDto>>? _logsSub;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ─── Lifecycle ────────────────────────────────────────────────────────────

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
    _logsSub = _firestoreService.watchSeizureLogs(_uid).listen(
      (list) {
        logs.value = list;
        screenState.value = GenericScreenStates.loaded;
      },
      onError: (_) => screenState.value = GenericScreenStates.error,
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<bool> addEntry({
    required DateTime occurredAt,
    int? durationSeconds,
    String? location,
    String? trigger,
    String? notes,
    bool alertFired = false,
  }) async {
    final log = SeizureLogDto(
      id: FirebaseFirestore.instance.collection(FirebaseCollectionKeys.seizureLogs).doc().id,
      userId: _uid,
      occurredAt: occurredAt,
      durationSeconds: durationSeconds,
      location: _clean(location),
      trigger: _clean(trigger),
      notes: _clean(notes),
      alertFired: alertFired,
    );
    final result = await _firestoreService.addSeizureLog(log);
    return result.isSuccess;
  }

  Future<bool> updateEntry({
    required String id,
    required DateTime occurredAt,
    int? durationSeconds,
    String? location,
    String? trigger,
    String? notes,
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
