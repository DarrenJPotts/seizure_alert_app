import 'dart:async';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/medication_reminder_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/local_notifications_service.dart';
import 'package:seizure_app/features/reminders/view_models/reminders_view_model.dart';
import 'package:seizure_app/features/safety_plan/view_models/safety_plan_view_model.dart';

class _Notifications extends LocalNotificationsService {
  List<MedicationReminderDto> scheduled = [];
  bool fail = false;
  @override
  Future<void> replaceMedicationReminders({
    required List<MedicationReminderDto> previous,
    required List<MedicationReminderDto> current,
  }) async {
    if (fail) throw StateError('Not available');
    scheduled = current;
  }
}

class _DelayedFirestore extends FirestoreService {
  _DelayedFirestore() : super(FakeFirebaseFirestore());
  final result = Completer<ResultDto<UserDto>>();
  @override
  Future<ResultDto<UserDto>> getUser(
    String uid, {
    bool requireCompleteProfile = false,
  }) => result.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeFirebaseFirestore db;
  late FirestoreService service;
  late _Notifications notifications;
  late RemindersViewModel vm;
  final now = DateTime(2026, 10, 22, 10);
  MedicationReminderDto r({
    String id = 'one',
    ReminderRepeat repeat = ReminderRepeat.daily,
  }) => MedicationReminderDto(
    id: id,
    name: 'Vitamins',
    hour: 9,
    minute: 0,
    kind: ReminderKind.supplement,
    repeat: repeat,
    startDate: DateTime(2026, 10, 22),
  );
  setUp(() async {
    Get.testMode = true;
    db = FakeFirebaseFirestore();
    await db
        .collection('users')
        .doc('user')
        .set(
          UserDto(
            uid: 'user',
            email: 'sample@example.com',
            medicationReminders: [r()],
          ).toMap(),
        );
    service = FirestoreService(db);
    notifications = _Notifications();
    vm = RemindersViewModel(
      service,
      notifications,
      currentUid: () => 'user',
      clock: () => now,
    );
    await vm.load();
  });
  tearDown(() {
    vm.onClose();
    Get.reset();
  });
  test(
    'snooze, completion and skip persist history and update native schedules',
    () async {
      expect(
        await vm.record(vm.reminders.single, ReminderAction.snoozed),
        isTrue,
      );
      expect(
        vm.reminders.single.snoozedUntil,
        now.add(const Duration(minutes: 15)),
      );
      expect(
        await vm.record(vm.reminders.single, ReminderAction.completed),
        isTrue,
      );
      expect(vm.reminders.single.snoozedUntil, isNull);
      expect(vm.reminders.single.history.map((e) => e.action), [
        ReminderAction.completed,
        ReminderAction.snoozed,
      ]);
      expect(
        await vm.record(vm.reminders.single, ReminderAction.skipped),
        isFalse,
      );
      final saved = (await service.getUser(
        'user',
      )).data!.medicationReminders.single;
      expect(saved.history.length, 2);
      expect(notifications.scheduled.single.revision, 2);
    },
  );
  test('one-off completion disables further notifications', () async {
    await db.collection('users').doc('user').update({
      'medicationReminders': [r(repeat: ReminderRepeat.once).toMap()],
    });
    await vm.load();
    expect(
      await vm.record(vm.reminders.single, ReminderAction.skipped),
      isTrue,
    );
    expect(vm.reminders.single.enabled, isFalse);
    expect(vm.reminders.single.history.single.action, ReminderAction.skipped);
  });
  test('cannot mark a future occurrence as taken', () async {
    final future = MedicationReminderDto(
      id: 'future',
      name: 'Appointment',
      hour: 12,
      minute: 0,
      repeat: ReminderRepeat.once,
      startDate: now,
    );
    expect(await vm.saveReminder(future), isTrue);
    expect(
      await vm.record(vm.reminders.last, ReminderAction.completed),
      isFalse,
    );
  });
  test(
    'transactions preserve other devices additions and reject stale edits',
    () async {
      final old = vm.reminders.single;
      await service.updateReminders(
        'user',
        (items) => [...items, r(id: 'two')],
      );
      expect(await vm.setEnabled(old, false), isTrue);
      expect(vm.reminders.length, 2);
      expect(await vm.remove(old), isFalse);
      expect(vm.reminders.length, 2);
      expect(vm.error.value, isNotNull);
      expect(
        (await service.getUser('user')).data!.medicationReminders.length,
        2,
      );
    },
  );
  test(
    'notification failure preserves the saved reminder and offers a warning',
    () async {
      notifications.fail = true;
      expect(await vm.saveReminder(r(id: 'two')), isTrue);
      expect(vm.reminders.length, 2);
      expect(vm.notificationWarning.value, contains('could not be scheduled'));
      notifications.fail = false;
      await vm.load();
      expect(vm.notificationWarning.value, isNull);
      expect(notifications.scheduled.length, 2);
    },
  );
  test('safety plan saves cannot overwrite reminder changes', () async {
    final plan = SafetyPlanViewModel(service, currentUid: () => 'user');
    await plan.load();
    await vm.saveReminder(r(id: 'two'));
    plan.actionPlanController.text = 'Saved instructions';
    expect(await plan.save(), isTrue);
    expect((await service.getUser('user')).data!.medicationReminders.length, 2);
    plan.onClose();
  });
  test('history is bounded to the most recent 100 actions', () async {
    final existing = r().copyWith(
      history: [
        for (var i = 0; i < 100; i++)
          ReminderEvent(
            occurrence: '2026-10-21T09:00:00.000',
            at: now.subtract(Duration(minutes: i + 1)),
            action: ReminderAction.snoozed,
          ),
      ],
    );
    await db.collection('users').doc('user').update({
      'medicationReminders': [existing.toMap()],
    });
    await vm.load();
    expect(
      await vm.record(vm.reminders.single, ReminderAction.completed),
      isTrue,
    );
    expect(vm.reminders.single.history.length, 100);
    expect(vm.reminders.single.history.first.action, ReminderAction.completed);
  });
  test(
    'account change or controller disposal during load never schedules another user',
    () async {
      final delayed = _DelayedFirestore();
      var uid = 'first';
      final local = _Notifications();
      final closing = RemindersViewModel(delayed, local, currentUid: () => uid);
      final pending = closing.load();
      uid = 'second';
      closing.onClose();
      delayed.result.complete(
        ResultDto.success(
          UserDto(
            uid: 'first',
            email: 'sample@example.com',
            medicationReminders: [r()],
          ),
        ),
      );
      await pending;
      expect(closing.reminders, isEmpty);
      expect(local.scheduled, isEmpty);
    },
  );
}
