import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/daily_log_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';

class DailyLogViewModel extends GetxController {
  DailyLogViewModel(
    this.store, {
    String? Function()? currentUid,
    DateTime Function()? clock,
  }) : _currentUid = currentUid,
       _clock = clock ?? DateTime.now;
  final FirestoreService store;
  final String? Function()? _currentUid;
  final DateTime Function() _clock;
  String get uid =>
      (_currentUid == null
          ? FirebaseAuth.instance.currentUser?.uid
          : _currentUid()) ??
      '';
  DateTime get today => dailyDate(_clock());
  late final selectedDate = today.obs;
  final entry = Rxn<DailyLogDto>();
  final loading = true.obs;
  final saving = false.obs;
  final error = RxnString();
  Future<bool> Function()? confirmDateChange;
  int _generation = 0;
  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final generation = ++_generation;
    final owner = uid;
    final day = selectedDate.value;
    loading.value = true;
    error.value = null;
    final result = await store.getDailyLog(owner, day);
    if (isClosed || generation != _generation || owner != uid) return;
    loading.value = false;
    if (result.isSuccess) {
      entry.value = result.data;
    } else {
      entry.value = null;
      error.value = result.error;
    }
  }

  Future<bool> selectDate(DateTime date) async {
    final day = dailyDate(date);
    if (day.isAfter(today) || day.year < 1900 || saving.value) return false;
    if (day == selectedDate.value) return true;
    if (confirmDateChange != null && !await confirmDateChange!()) return false;
    if (isClosed) return false;
    selectedDate.value = day;
    entry.value = null;
    await load();
    return !isClosed;
  }

  Future<bool> save(DailyLogDto draft, DailyLogDto? expected) async {
    if (saving.value || loading.value || uid.isEmpty) return false;
    final validation = draft.validate(today);
    if (validation != null) {
      error.value = validation;
      return false;
    }
    final owner = uid;
    saving.value = true;
    error.value = null;
    try {
      final result = await store.saveDailyLog(owner, draft, expected: expected);
      if (isClosed || owner != uid) return false;
      if (!result.isSuccess) {
        error.value = result.error;
        return false;
      }
      if (dailyDate(draft.date) == selectedDate.value) {
        entry.value = result.data;
      }
      return true;
    } finally {
      if (!isClosed) saving.value = false;
    }
  }

  Future<bool> remove(DailyLogDto expected) async {
    if (saving.value || loading.value) return false;
    final owner = uid;
    saving.value = true;
    try {
      final result = await store.deleteDailyLog(owner, expected);
      if (isClosed || owner != uid) return false;
      if (!result.isSuccess) {
        error.value = result.error;
        return false;
      }
      entry.value = null;
      error.value = null;
      return true;
    } finally {
      if (!isClosed) saving.value = false;
    }
  }

  @override
  void onClose() {
    ++_generation;
    confirmDateChange = null;
    super.onClose();
  }
}

class DailyLogBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DailyLogViewModel>()) {
      Get.lazyPut(() => DailyLogViewModel(FirestoreService.instance()));
    }
  }
}
