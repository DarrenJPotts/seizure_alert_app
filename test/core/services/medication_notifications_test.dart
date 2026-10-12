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
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls = <MethodCall>[];
    zone = 'Asia/Tokyo';
    messenger.setMockMethodCallHandler(zoneChannel, (_) async => zone);
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'initialize') return true;
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
}
