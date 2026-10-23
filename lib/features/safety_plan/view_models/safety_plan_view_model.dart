import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';

class SafetyPlanViewModel extends GetxController {
  SafetyPlanViewModel(this._firestore, {String? Function()? currentUid})
    : _currentUid = currentUid;
  final String? Function()? _currentUid;

  final FirestoreService _firestore;

  final TextEditingController actionPlanController = TextEditingController();
  final TextEditingController rescueMedicationController =
      TextEditingController();
  final RxInt callEmergencyAfterMinutes = 5.obs;
  final RxBool nearbyAudibleAlert = false.obs;
  final RxBool loading = true.obs;
  final RxBool saving = false.obs;
  final RxnString error = RxnString();

  bool get hasLoadedPlan => _user != null;

  UserDto? _user;

  String get _uid =>
      (_currentUid != null
          ? _currentUid()
          : FirebaseAuth.instance.currentUser?.uid) ??
      '';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final uid = _uid;
    final result = await _firestore.getUser(uid);
    if (isClosed || uid != _uid) return;
    if (!result.isSuccess || result.data == null) {
      error.value = 'Your safety plan could not be loaded.';
      loading.value = false;
      return;
    }
    _user = result.data;
    actionPlanController.text = _user?.seizureActionPlan ?? '';
    rescueMedicationController.text = _user?.rescueMedication ?? '';
    callEmergencyAfterMinutes.value = _user!.callEmergencyAfterMinutes;
    nearbyAudibleAlert.value = _user!.nearbyAudibleAlert;
    loading.value = false;
  }

  Future<bool> save() async {
    if (saving.value || _uid.isEmpty) return false;
    final uid = _uid;
    saving.value = true;
    error.value = null;
    try {
      final result = await _firestore.updateSafetyPlan(uid, <String, dynamic>{
        'seizureActionPlan': actionPlanController.text.trim(),
        'rescueMedication': rescueMedicationController.text.trim(),
        'callEmergencyAfterMinutes': callEmergencyAfterMinutes.value,
        'nearbyAudibleAlert': nearbyAudibleAlert.value,
      });
      if (isClosed || uid != _uid) return false;
      if (!result.isSuccess) {
        error.value = 'Your safety plan could not be saved.';
        return false;
      }

      return true;
    } finally {
      if (!isClosed) saving.value = false;
    }
  }

  @override
  void onClose() {
    actionPlanController.dispose();
    rescueMedicationController.dispose();
    super.onClose();
  }
}

class SafetyPlanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SafetyPlanViewModel(FirestoreService.instance()));
  }
}
