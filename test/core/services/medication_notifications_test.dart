import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/dtos/medication_reminder_dto.dart';
import 'package:seizure_app/core/services/local_notifications_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  const zoneChannel = MethodChannel('flutter_timezone');
  const reminder = MedicationReminderDto(
    id: 'test',
    name: 'Test medication',
    hour: 8,
    minute: 15,
  );
  late LocalNotificationsService service;
  late List<MethodCall> calls;
  String? zone;
  bool launchedFromReminder = false;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls = <MethodCall>[];
    zone = 'Asia/Tokyo';
    launchedFromReminder = false;
    messenger.setMockMethodCallHandler(zoneChannel, (_) async => zone);
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'initialize') return true;
      if (call.method == 'getNotificationAppLaunchDetails' &&
          launchedFromReminder) {
        return {
          'notificationLaunchedApp': true,
          'notificationResponse': {
            'notificationId': 100123,
            'notificationResponseType': 0,
            'payload': '/reminders',
          },
        };
      }
      if (call.method == 'pendingNotificationRequests') {
        return <Map<String, Object>>[
          {
            'id': 100123,
            'title': 'Old reminder',
            'body': '',
            'payload': '/safety-plan',
          },
          {'id': 900001, 'title': 'Emergency', 'body': '', 'payload': '/'},
        ];
      }
      return null;
    });
    service = await LocalNotificationsService().init();
    calls.clear();
  });

  tearDown(() {
    service.onClose();
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(zoneChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'schedules in the device timezone and clears stale medication IDs only',
    () async {
      await service.replaceMedicationReminders(
        previous: const [],
        current: const [reminder],
      );
      final scheduled =
          calls.singleWhere((call) => call.method == 'zonedSchedule').arguments
              as Map;
      expect(scheduled['timeZoneName'], 'Asia/Tokyo');
      expect(scheduled['scheduledDateTime'], contains('08:15:00'));
      final cancelled = calls
          .where((call) => call.method == 'cancel')
          .map((call) => (call.arguments as Map)['id']);
      expect(cancelled, contains(100123));
      expect(cancelled, isNot(contains(900001)));
    },
  );

  test('reschedules on resume after device timezone changes', () async {
    await service.replaceMedicationReminders(
      previous: const [],
      current: const [reminder],
    );
    calls.clear();
    zone = 'Europe/London';
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    // Clearing is queued after the refresh, so it also waits for that refresh.
    await service.clearMedicationReminders();
    final scheduled =
        calls.singleWhere((call) => call.method == 'zonedSchedule').arguments
            as Map;
    expect(scheduled['timeZoneName'], 'Europe/London');
  });

  test(
    'timezone detection failure preserves existing native schedules',
    () async {
      zone = null;
      await expectLater(
        service.replaceMedicationReminders(
          previous: const [],
          current: const [reminder],
        ),
        throwsArgumentError,
      );
      expect(calls.where((call) => call.method == 'cancel'), isEmpty);
    },
  );

  test(
    'account cleanup clears schedules and prevents resume resurrection',
    () async {
      await service.replaceMedicationReminders(
        previous: const [],
        current: const [reminder],
      );
      await service.clearMedicationReminders();
      calls.clear();
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await service.clearMedicationReminders();
      expect(calls.where((call) => call.method == 'zonedSchedule'), isEmpty);
    },
  );

  test(
    'cold notification launch is queued until authentication and cleared on account cleanup',
    () async {
      launchedFromReminder = true;
      final cold = await LocalNotificationsService().init();
      expect(cold.reminderLaunchRequested, isTrue);
      await cold.clearMedicationReminders();
      expect(cold.reminderLaunchRequested, isFalse);
      cold.onClose();
    },
  );

  test(
    'weekly and monthly schedules use native repeats; appointments do not repeat',
    () async {
      await service.replaceMedicationReminders(
        previous: [],
        current: [
          const MedicationReminderDto(
            id: 'weekly',
            name: 'Vitamins',
            hour: 9,
            minute: 0,
            kind: ReminderKind.supplement,
            repeat: ReminderRepeat.weekdays,
            weekdays: [1, 7],
          ),
          const MedicationReminderDto(
            id: 'monthly',
            name: 'Refill',
            hour: 10,
            minute: 0,
            repeat: ReminderRepeat.monthly,
            monthDay: 31,
          ),
          MedicationReminderDto(
            id: 'appointment',
            name: 'Appointment',
            hour: 14,
            minute: 0,
            repeat: ReminderRepeat.once,
            startDate: DateTime.now().add(const Duration(days: 3)),
          ),
        ],
      );
      final scheduled = calls
          .where((c) => c.method == 'zonedSchedule')
          .map((c) => c.arguments as Map)
          .toList();
      expect(scheduled.length, 4);
      expect(
        scheduled
            .where(
              (c) =>
                  c['matchDateTimeComponents'] ==
                  DateTimeComponents.dayOfWeekAndTime.index,
            )
            .length,
        2,
      );
      expect(
        scheduled
            .where(
              (c) =>
                  c['matchDateTimeComponents'] ==
                  DateTimeComponents.dayOfMonthAndTime.index,
            )
            .length,
        1,
      );
      expect(
        scheduled
            .where((c) => !c.containsKey('matchDateTimeComponents'))
            .length,
        1,
      );
      expect(scheduled.every((c) => c['payload'] == '/reminders'), isTrue);
      expect(scheduled.map((c) => c['id']).toSet().length, 4);
    },
  );

  test('invalid schedules never cancel existing native reminders', () async {
    await expectLater(
      service.replaceMedicationReminders(
        previous: [],
        current: const [
          MedicationReminderDto(
            id: 'invalid',
            name: 'Invalid',
            hour: 9,
            minute: 0,
            repeat: ReminderRepeat.weekly,
          ),
        ],
      ),
      throwsArgumentError,
    );
    expect(calls.where((call) => call.method == 'cancel'), isEmpty);
  });
}
