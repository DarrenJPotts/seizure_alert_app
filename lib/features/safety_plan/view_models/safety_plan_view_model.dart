import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/medication_reminder_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/firebase_messaging_service.dart';
import 'package:seizure_app/core/services/local_notifications_service.dart';

class SafetyPlanViewModel extends GetxController {
  SafetyPlanViewModel(
    this._firestore,
    this._notifications, {
    String? Function()? currentUid,
  }) : _currentUid = currentUid;
  final String? Function()? _currentUid;

  final FirestoreService _firestore;
  final LocalNotificationsService? _notifications;

  final TextEditingController actionPlanController = TextEditingController();
  final TextEditingController rescueMedicationController =
      TextEditingController();
  final RxList<MedicationReminderDto> reminders = <MedicationReminderDto>[].obs;
  final RxInt callEmergencyAfterMinutes = 5.obs;
  final RxBool nearbyAudibleAlert = false.obs;
  final RxBool loading = true.obs;
  final RxBool saving = false.obs;
  final RxnString error = RxnString();

  bool get hasLoadedPlan => _user != null;

  UserDto? _user;
  List<MedicationReminderDto> _savedReminders = <MedicationReminderDto>[];

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
    reminders.assignAll(_user!.medicationReminders);
    _savedReminders = List<MedicationReminderDto>.from(reminders);
    loading.value = false;
  }

  void addReminder(MedicationReminderDto reminder) => reminders.add(reminder);

  void removeReminder(String id) {
    reminders.removeWhere((MedicationReminderDto item) => item.id == id);
  }

  void setReminderEnabled(String id, bool enabled) {
    final int index = reminders.indexWhere(
      (MedicationReminderDto item) => item.id == id,
    );
    if (index == -1) return;
    reminders[index] = reminders[index].copyWith(enabled: enabled);
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
        'medicationReminders': reminders
            .map((MedicationReminderDto reminder) => reminder.toMap())
            .toList(),
      });
      if (isClosed || uid != _uid) return false;
      if (!result.isSuccess) {
        error.value = 'Your safety plan could not be saved.';
        return false;
      }

      final bool hasEnabledReminder = reminders.any(
        (MedicationReminderDto reminder) => reminder.enabled,
      );
      final FirebaseMessagingService? messaging =
          Get.isRegistered<FirebaseMessagingService>()
          ? Get.find<FirebaseMessagingService>()
          : null;
      if (hasEnabledReminder) {
        await messaging?.enableNotifications();
        if (isClosed || uid != _uid) return false;
        if (messaging?.notificationsAuthorized != true) {
          error.value =
              'Safety plan saved. Enable notifications to receive reminders.';
          return false;
        }
      }
      if (_notifications == null) {
        if (!hasEnabledReminder && _savedReminders.isEmpty) {
          _savedReminders = List<MedicationReminderDto>.from(reminders);
          return true;
        }
        error.value =
            'Safety plan saved, but reminders are unavailable on this device.';
        return false;
      }
      try {
        await _notifications.replaceMedicationReminders(
          previous: _savedReminders,
          current: List<MedicationReminderDto>.from(reminders),
        );
      } catch (_) {
        error.value =
            'Safety plan saved, but reminders could not be scheduled.';
        return false;
      }
      _savedReminders = List<MedicationReminderDto>.from(reminders);
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
    Get.lazyPut(
      () => SafetyPlanViewModel(
        FirestoreService.instance(),
        Get.isRegistered<LocalNotificationsService>()
            ? Get.find<LocalNotificationsService>()
            : null,
      ),
    );
  }
}
