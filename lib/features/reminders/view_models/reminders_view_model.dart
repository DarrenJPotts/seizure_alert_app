import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/medication_reminder_dto.dart';
import 'package:seizure_app/core/helpers/reminder_schedule.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/firebase_messaging_service.dart';
import 'package:seizure_app/core/services/local_notifications_service.dart';

class RemindersViewModel extends GetxController with WidgetsBindingObserver {
  RemindersViewModel(
    this._firestore,
    this._notifications, {
    String? Function()? currentUid,
    DateTime Function()? clock,
  }) : _currentUid = currentUid,
       _clock = clock ?? DateTime.now;
  final FirestoreService _firestore;
  final LocalNotificationsService? _notifications;
  final String? Function()? _currentUid;
  final DateTime Function() _clock;
  final reminders = <MedicationReminderDto>[].obs;
  final loading = true.obs;
  final busy = false.obs;
  final error = RxnString();
  final notificationWarning = RxnString();
  final now = DateTime.now().obs;
  Timer? _timer;
  int _generation = 0;
  String get _uid =>
      (_currentUid != null
          ? _currentUid()
          : FirebaseAuth.instance.currentUser?.uid) ??
      '';

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    now.value = _clock();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => now.value = _clock(),
    );
    unawaited(load());
  }

  Future<void> load() async {
    if (busy.value) return;
    final generation = ++_generation;
    final uid = _uid;
    if (uid.isEmpty) {
      error.value = 'Sign in to manage reminders.';
      loading.value = false;
      return;
    }
    loading.value = true;
    error.value = null;
    final result = await _firestore.getUser(uid);
    if (isClosed || uid != _uid || generation != _generation) return;
    loading.value = false;
    if (!result.isSuccess || result.data == null) {
      error.value = 'Your reminders could not be loaded.';
      return;
    }
    final previous = reminders.toList();
    reminders.assignAll(result.data!.medicationReminders);
    now.value = _clock();
    await _schedule(previous, uid);
  }

  Future<void> _schedule(
    List<MedicationReminderDto> previous,
    String uid, {
    bool requestPermission = false,
  }) async {
    notificationWarning.value = null;
    try {
      if (requestPermission &&
          reminders.any((r) => r.enabled) &&
          Get.isRegistered<FirebaseMessagingService>()) {
        final messaging = Get.find<FirebaseMessagingService>();
        if (!messaging.notificationsAuthorized) {
          await messaging.enableNotifications();
        }
      }
      if (isClosed || uid != _uid) return;
      if (_notifications == null) throw StateError('Notifications unavailable');
      await _notifications.replaceMedicationReminders(
        previous: previous,
        current: reminders.toList(),
      );
      if (!isClosed &&
          uid == _uid &&
          reminders.any((r) => r.enabled) &&
          Get.isRegistered<FirebaseMessagingService>() &&
          !Get.find<FirebaseMessagingService>().notificationsAuthorized) {
        notificationWarning.value =
            'Enable notifications in Profile to receive reminders on this phone.';
      }
    } catch (_) {
      if (!isClosed && uid == _uid) {
        notificationWarning.value =
            'Reminders are saved, but notifications could not be scheduled on this phone. Check notification settings and retry.';
      }
    }
  }

  Future<bool> _change(
    List<MedicationReminderDto> Function(List<MedicationReminderDto>)
    transform, {
    bool requestPermission = false,
  }) async {
    if (busy.value || loading.value || _uid.isEmpty) return false;
    final uid = _uid;
    final previous = reminders.toList();
    busy.value = true;
    error.value = null;
    try {
      final result = await _firestore.updateReminders(uid, (current) {
        final next = transform(current);
        reminderNotificationSlots(
          next,
          _clock(),
        ); // Validate capacity before writing.
        return next;
      });
      if (isClosed || uid != _uid) return false;
      if (!result.isSuccess || result.data == null) {
        error.value = result.error;
        return false;
      }
      reminders.assignAll(result.data!);
      now.value = _clock();
      await _schedule(previous, uid, requestPermission: requestPermission);
      return true;
    } finally {
      if (!isClosed) busy.value = false;
    }
  }

  Future<bool> saveReminder(
    MedicationReminderDto value, {
    int? expectedRevision,
  }) {
    if (value.validationError != null) {
      error.value = value.validationError;
      return Future.value(false);
    }
    if (value.repeat == ReminderRepeat.once &&
        nextReminderOccurrence(value, _clock()) == null &&
        value.enabled) {
      error.value = 'Choose a future date and time.';
      return Future.value(false);
    }
    return _change((items) {
      final index = items.indexWhere((e) => e.id == value.id);
      if (expectedRevision == null) {
        if (index != -1) throw StateError('Already exists');
        return [...items, value];
      }
      if (index == -1 || items[index].revision != expectedRevision) {
        throw StateError('Reminder changed');
      }
      items[index] = value.copyWith(
        history: items[index].history,
        revision: expectedRevision + 1,
        clearSnooze: true,
      );
      return items;
    }, requestPermission: true);
  }

  Future<bool> setEnabled(MedicationReminderDto reminder, bool enabled) =>
      _change((items) {
        final i = _find(items, reminder);
        final updated = items[i].copyWith(
          enabled: enabled,
          clearSnooze: true,
          revision: items[i].revision + 1,
        );
        if (enabled &&
            updated.repeat == ReminderRepeat.once &&
            nextReminderOccurrence(updated, _clock()) == null) {
          throw StateError('Edit expired reminder');
        }
        items[i] = updated;
        return items;
      }, requestPermission: enabled);

  Future<bool> remove(MedicationReminderDto reminder) => _change((items) {
    items.removeAt(_find(items, reminder));
    return items;
  });

  Future<bool> record(
    MedicationReminderDto reminder,
    ReminderAction action, {
    int snoozeMinutes = 15,
  }) {
    final occurred = actionableReminderOccurrence(reminder, _clock());
    if (occurred == null) return Future.value(false);
    final key = reminderOccurrenceKey(occurred);
    return _change((items) {
      final i = _find(items, reminder);
      final current = items[i];
      if (current.isResolved(key) ||
          reminderOccurrenceKey(
                actionableReminderOccurrence(current, _clock()) ?? _clock(),
              ) !=
              key) {
        throw StateError('Occurrence changed');
      }
      if (snoozeMinutes < 1 || snoozeMinutes > 60) {
        throw ArgumentError('Invalid snooze');
      }
      final at = _clock();
      final snooze = action == ReminderAction.snoozed;
      items[i] = current.copyWith(
        enabled: current.repeat == ReminderRepeat.once && !snooze
            ? false
            : current.enabled,
        revision: current.revision + 1,
        history: [
          ReminderEvent(occurrence: key, at: at, action: action),
          ...current.history,
        ].take(100).toList(),
        clearSnooze: !snooze,
        snoozedUntil: snooze ? at.add(Duration(minutes: snoozeMinutes)) : null,
        snoozedOccurrence: snooze ? key : null,
      );
      return items;
    }, requestPermission: action == ReminderAction.snoozed);
  }

  int _find(List<MedicationReminderDto> items, MedicationReminderDto expected) {
    final i = items.indexWhere((e) => e.id == expected.id);
    if (i == -1 || items[i].revision != expected.revision) {
      throw StateError('Reminder changed');
    }
    return i;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      now.value = _clock();
      unawaited(load());
    }
  }

  @override
  void onClose() {
    ++_generation;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}

class RemindersBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<RemindersViewModel>()) return;
    Get.lazyPut(
      () => RemindersViewModel(
        FirestoreService.instance(),
        Get.isRegistered<LocalNotificationsService>()
            ? Get.find<LocalNotificationsService>()
            : null,
      ),
    );
  }
}
