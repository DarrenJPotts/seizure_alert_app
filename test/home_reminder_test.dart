// ignore_for_file: must_call_super
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/medication_reminder_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/helpers/reminder_schedule.dart';
import 'package:seizure_app/core/services/alert_drill_service.dart';
import 'package:seizure_app/core/services/circle_invite_service.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/features/home/home_view.dart';
import 'package:seizure_app/features/home/view_models/home_view_model.dart';
import 'package:seizure_app/features/home/widgets/setup_check_card.dart';
import 'package:seizure_app/features/home/widgets/upcoming_reminder_card.dart';
import 'package:seizure_app/features/home/models/home_reminder_summary.dart';
import 'package:seizure_app/features/contacts/view_models/contacts_view_model.dart';
import 'package:seizure_app/features/reminders/view_models/reminders_view_model.dart';

class _Firestore extends Fake implements FirestoreService {}

class _Invites extends Fake implements CircleInviteService {}

class _Drills extends Fake implements AlertDrillService {}

class _Home extends HomeViewModel {
  _Home() : super(_Firestore());
  @override
  void onInit() {}
  @override
  String get firstName => user.value?.displayName ?? 'Alex';
}

class _Contacts extends ContactsViewModel {
  _Contacts() : super(_Firestore(), _Invites(), _Drills());
  @override
  void onInit() {}
}

class _Reminders extends RemindersViewModel {
  _Reminders() : super(_Firestore(), null);
  @override
  void onInit() {}
}

final now = DateTime(2026, 10, 22, 9, 30);
MedicationReminderDto reminder({
  String id = 'medication',
  int hour = 10,
  bool enabled = true,
}) => MedicationReminderDto(
  id: id,
  name: 'Morning medication',
  hour: hour,
  minute: 0,
  enabled: enabled,
  startDate: DateTime(2026, 10, 22),
);
RemindersViewModel fixture() {
  final vm = Get.put<RemindersViewModel>(_Reminders());
  vm.now.value = now;
  vm.loading.value = false;
  vm.reminders.assignAll([reminder()]);
  return vm;
}

void main() {
  setUp(() {
    Get.testMode = true;
  });
  tearDown(Get.reset);
  test(
    'summary orders due, snoozed and upcoming reminders and excludes disabled',
    () {
      final due = reminder(id: 'due', hour: 8);
      final future = reminder(id: 'future', hour: 11);
      final snoozed = due.copyWith(
        snoozedUntil: now.add(const Duration(minutes: 15)),
        snoozedOccurrence: reminderOccurrenceKey(DateTime(2026, 10, 22, 8)),
      );
      expect(homeReminderSummary([future, due], now)!.reminder.id, 'due');
      expect(homeReminderSummary([future, snoozed], now)!.snoozed, isTrue);
      expect(
        homeReminderSummary([future, snoozed], now)!.at,
        now.add(const Duration(minutes: 15)),
      );
      final completed = due.copyWith(
        history: [
          ReminderEvent(
            occurrence: reminderOccurrenceKey(DateTime(2026, 10, 22, 8)),
            at: now,
            action: ReminderAction.completed,
          ),
        ],
      );
      expect(
        homeReminderSummary([completed, future], now)!.reminder.id,
        'future',
      );
      expect(homeReminderSummary([reminder(enabled: false)], now), isNull);
      expect(homeReminderSummary([], now), isNull);
    },
  );
  test(
    'one-off completion and expired snooze use existing occurrence rules',
    () {
      final once = MedicationReminderDto(
        id: 'once',
        name: 'Appointment',
        hour: 8,
        minute: 0,
        repeat: ReminderRepeat.once,
        startDate: now,
      );
      final done = once.copyWith(
        history: [
          ReminderEvent(
            occurrence: reminderOccurrenceKey(DateTime(2026, 10, 22, 8)),
            at: now,
            action: ReminderAction.skipped,
          ),
        ],
      );
      expect(homeReminderSummary([done], now), isNull);
      final expired = once.copyWith(
        snoozedUntil: now.subtract(const Duration(minutes: 1)),
        snoozedOccurrence: reminderOccurrenceKey(DateTime(2026, 10, 22, 8)),
      );
      expect(homeReminderSummary([expired], now)!.snoozed, isFalse);
      expect(homeReminderSummary([expired], now)!.at.isBefore(now), isTrue);
    },
  );
  test('route binding retains shared Home reminders controller', () {
    final vm = fixture();
    RemindersBinding().dependencies();
    expect(Get.find<RemindersViewModel>(), same(vm));
  });
  for (final dark in [false, true]) {
    for (final scale in [1.0, 3.0]) {
      testWidgets(
        'Home shortcut reacts and opens reminders dark=$dark scale=$scale',
        (tester) async {
          tester.view.physicalSize = const Size(280, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final vm = fixture();
          var opened = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: UpcomingReminderCard(onOpen: () => opened++),
                  ),
                ),
              ),
            ),
          );
          expect(find.text('Next reminder'), findsOneWidget);
          expect(find.text('Morning medication'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('View reminders'));
          expect(opened, 1);
          vm.now.value = DateTime(2026, 10, 22, 10, 1);
          await tester.pump();
          expect(find.text('Reminder due'), findsOneWidget);
          vm.reminders.clear();
          await tester.pump();
          expect(find.text('No upcoming reminders'), findsOneWidget);
          vm.error.value = 'Load failed';
          await tester.pump();
          expect(find.text('Open reminders to retry'), findsOneWidget);
          vm.error.value = null;
          vm.notificationWarning.value = 'Permission denied';
          vm.loading.value = true;
          await tester.pump();
          expect(find.text('Loading reminders…'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('Home places reminders directly below setup check', (
    tester,
  ) async {
    fixture();
    Get.put<HomeViewModel>(_Home()).screenState.value =
        GenericScreenStates.loaded;
    Get.put<ContactsViewModel>(_Contacts()).screenState.value =
        GenericScreenStates.loaded;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: HomeView(onOpenContacts: () {})),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(UpcomingReminderCard)).dy,
      greaterThanOrEqualTo(
        tester.getBottomLeft(find.byType(SetupCheckCard)).dy,
      ),
    );
    expect(find.text('Morning medication'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('render Home reminder preview', (tester) async {
    if (!const bool.fromEnvironment('HOME_REMINDER_PREVIEW')) return;
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    fixture();
    Get.put<HomeViewModel>(_Home()).screenState.value =
        GenericScreenStates.loaded;
    Get.put<ContactsViewModel>(_Contacts()).screenState.value =
        GenericScreenStates.loaded;
    await tester.runAsync(() async {
      await (FontLoader('RedHatDisplay')
            ..addFont(rootBundle.load('assets/fonts/RedHatDisplay-Regular.ttf'))
            ..addFont(
              rootBundle.load('assets/fonts/RedHatDisplay-SemiBold.ttf'),
            )
            ..addFont(rootBundle.load('assets/fonts/RedHatDisplay-Bold.ttf')))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Seizure Alert')),
            body: HomeView(onOpenContacts: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'docs/design/home-reminder-preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
