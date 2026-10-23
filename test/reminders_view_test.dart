import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/medication_reminder_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/local_notifications_service.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:seizure_app/features/reminders/reminders_view.dart';
import 'package:seizure_app/features/reminders/view_models/reminders_view_model.dart';

class _Notifications extends LocalNotificationsService {
  @override
  Future<void> replaceMedicationReminders({
    required List<MedicationReminderDto> previous,
    required List<MedicationReminderDto> current,
  }) async {}
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);
  final now = DateTime(2026, 10, 22, 10);
  Future<RemindersViewModel> fixture() async {
    final db = FakeFirebaseFirestore();
    await db
        .collection('users')
        .doc('sample')
        .set(
          UserDto(
            uid: 'sample',
            email: 'sample@example.com',
            medicationReminders: [
              MedicationReminderDto(
                id: 'vitamins',
                name: 'Take vitamins',
                kind: ReminderKind.supplement,
                repeat: ReminderRepeat.weekly,
                weekdays: [4],
                startDate: DateTime(2026, 10, 22),
                hour: 9,
                minute: 0,
              ),
            ],
          ).toMap(),
        );
    final vm = RemindersViewModel(
      FirestoreService(db),
      _Notifications(),
      currentUid: () => 'sample',
      clock: () => now,
    );
    await vm.load();
    Get.put(vm);
    return vm;
  }

  var fontsLoaded = false;
  for (final dark in [false, true]) {
    testWidgets('render reminder preview dark=$dark', (tester) async {
      if (!const bool.fromEnvironment('REMINDERS_PREVIEW')) return;
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      if (!fontsLoaded) {
        await tester.runAsync(() async {
          await (FontLoader('RedHatDisplay')
                ..addFont(
                  rootBundle.load('assets/fonts/RedHatDisplay-Regular.ttf'),
                )
                ..addFont(
                  rootBundle.load('assets/fonts/RedHatDisplay-SemiBold.ttf'),
                )
                ..addFont(
                  rootBundle.load('assets/fonts/RedHatDisplay-Bold.ttf'),
                ))
              .load();
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        });
        fontsLoaded = true;
      }
      final vm = await fixture();
      final oldShadows = debugDisableShadows;
      debugDisableShadows = false;
      try {
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: GetMaterialApp(
              debugShowCheckedModeBanner: false,
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: const RemindersView(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Future<void> capture(String section) async {
          expect(tester.takeException(), isNull);
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 3);
            final bytes = (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!;
            await Directory('docs/design').create(recursive: true);
            await File(
              'docs/design/reminders-${dark ? 'dark' : 'light'}-$section.png',
            ).writeAsBytes(bytes.buffer.asUint8List());
            image.dispose();
          });
        }

        await capture('overview');
        await tester.tap(find.byTooltip('Reminder options'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();
        await capture('editor');
      } finally {
        debugDisableShadows = oldShadows;
        vm.onClose();
      }
    });
  }

  for (final dark in [false, true]) {
    for (final scale in [1.0, 3.0]) {
      for (final width in [280.0, 390.0]) {
        testWidgets(
          'reminder actions and editor width=$width text=$scale dark=$dark',
          (tester) async {
            tester.view.physicalSize = Size(width, 700);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final vm = await fixture();
            await tester.pumpWidget(
              GetMaterialApp(
                theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    viewPadding: const EdgeInsets.only(bottom: 24),
                  ),
                  child: child!,
                ),
                home: const RemindersView(),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.scrollUntilVisible(
              find.text('Mark taken').hitTestable(),
              250,
              maxScrolls: 40,
            );
            await tester.tap(find.text('Mark taken'));
            await tester.pumpAndSettle();
            expect(
              vm.reminders.single.history.single.action,
              ReminderAction.completed,
            );
            await tester.scrollUntilVisible(
              find.text('History').hitTestable(),
              -250,
              maxScrolls: 40,
            );
            await tester.tap(find.text('History'));
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.textContaining('Taken ·').hitTestable(),
              250,
              maxScrolls: 40,
            );
            expect(find.textContaining('Taken ·'), findsOneWidget);
            await tester.tap(find.byTooltip('Add reminder'));
            await tester.pumpAndSettle();
            expect(find.byType(AppBottomSheetContent), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.scrollUntilVisible(
              find.text('Save reminder').hitTestable(),
              250,
              maxScrolls: 40,
              scrollable: find
                  .descendant(
                    of: find.byType(AppBottomSheetContent),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.tap(find.text('Save reminder'));
            await tester.pumpAndSettle();
            expect(find.text('Enter a name.'), findsOneWidget);
            expect(tester.takeException(), isNull);
            vm.onClose();
          },
        );
      }
    }
  }

  testWidgets('adds a weekly Sunday vitamin reminder from the editor', (
    tester,
  ) async {
    final vm = await fixture();
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.lightTheme, home: const RemindersView()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add reminder'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<ReminderKind>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vitamin / supplement').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Weekly vitamins');
    await tester.scrollUntilVisible(
      find.byType(DropdownButtonFormField<ReminderRepeat>),
      200,
      scrollable: find
          .descendant(
            of: find.byType(AppBottomSheetContent),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byType(DropdownButtonFormField<ReminderRepeat>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekly').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Sun'),
      150,
      scrollable: find
          .descendant(
            of: find.byType(AppBottomSheetContent),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Sun'));
    await tester.scrollUntilVisible(
      find.text('Save reminder').hitTestable(),
      200,
      scrollable: find
          .descendant(
            of: find.byType(AppBottomSheetContent),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Save reminder'));
    await tester.pumpAndSettle();
    expect(find.byType(AppBottomSheetContent), findsNothing);
    expect(vm.reminders.last.name, 'Weekly vitamins');
    expect(vm.reminders.last.repeat, ReminderRepeat.weekly);
    expect(vm.reminders.last.weekdays, [7]);
    expect(vm.reminders.last.kind, ReminderKind.supplement);
    expect(tester.takeException(), isNull);
    vm.onClose();
  });
}
