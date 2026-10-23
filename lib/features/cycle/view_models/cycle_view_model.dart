import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/cycle_tracking_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';

class CycleViewModel extends GetxController with WidgetsBindingObserver {
  CycleViewModel(
    this._store, {
    String? Function()? currentUid,
    DateTime Function()? clock,
  }) : _currentUid = currentUid,
       _clock = clock ?? DateTime.now;
  final FirestoreService _store;
  final String? Function()? _currentUid;
  final DateTime Function() _clock;
  final data = const CycleTrackingDto().obs;
  final loading = true.obs;
  final busy = false.obs;
  final error = RxnString();
  int _generation = 0;
  String get _uid =>
      (_currentUid == null
          ? FirebaseAuth.instance.currentUser?.uid
          : _currentUid()) ??
      '';
  DateTime get today => cycleDate(_clock());
  String newEntryId() => _store.newDocumentId('users');
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    unawaited(load());
  }

  Future<void> load() async {
    if (busy.value) return;
    final generation = ++_generation;
    final uid = _uid;
    loading.value = true;
    error.value = null;
    final result = await _store.getCycleTracking(uid);
    if (isClosed || generation != _generation || uid != _uid) return;
    loading.value = false;
    if (result.isSuccess && result.data != null) {
      data.value = result.data!;
    } else {
      data.value = const CycleTrackingDto();
      error.value = result.error;
    }
  }

  Future<bool> _change(
    CycleTrackingDto Function(CycleTrackingDto) change,
  ) async {
    if (busy.value || loading.value || _uid.isEmpty) return false;
    final uid = _uid;
    busy.value = true;
    error.value = null;
    try {
      final result = await _store.updateCycleTracking(
        uid,
        data.value.revision,
        change,
      );
      if (isClosed || uid != _uid) return false;
      if (!result.isSuccess || result.data == null) {
        error.value = result.error;
        return false;
      }
      data.value = result.data!;
      return true;
    } finally {
      if (!isClosed) busy.value = false;
    }
  }

  Future<bool> setEnabled(bool enabled) =>
      _change((current) => current.copyWith(enabled: enabled));
  Future<bool> save(CycleEntryDto entry) {
    final validation = entry.validate(today);
    if (validation != null) {
      error.value = validation;
      return Future.value(false);
    }
    if (!data.value.enabled) {
      error.value = 'Enable cycle tracking before adding an entry.';
      return Future.value(false);
    }
    if (data.value.entries.length >= 120 &&
        !data.value.entries.any((value) => value.id == entry.id)) {
      error.value =
          'You can keep up to 120 entries. Remove an older entry before adding another.';
      return Future.value(false);
    }
    final overlaps = data.value.entries.any(
      (other) =>
          other.id != entry.id &&
          !cycleDate(entry.start).isAfter(cycleDate(other.end ?? today)) &&
          !cycleDate(other.start).isAfter(cycleDate(entry.end ?? today)),
    );
    if (overlaps) {
      error.value =
          'These dates overlap another entry. Edit that entry or choose different dates.';
      return Future.value(false);
    }
    return _change((current) {
      if (!current.enabled) throw StateError('Tracking disabled');
      final entries =
          current.entries.where((other) => other.id != entry.id).toList()
            ..add(entry);
      entries.sort((a, b) => b.start.compareTo(a.start));
      return current.copyWith(entries: entries);
    });
  }

  Future<bool> remove(String id) => _change(
    (current) => current.copyWith(
      entries: current.entries.where((entry) => entry.id != id).toList(),
    ),
  );
  Future<bool> deleteAll() =>
      _change((current) => current.copyWith(entries: []));
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(load());
  }

  @override
  void onClose() {
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}

class CycleBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CycleViewModel>()) {
      Get.lazyPut(() => CycleViewModel(FirestoreService.instance()));
    }
  }
}
