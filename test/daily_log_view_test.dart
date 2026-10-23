import 'package:seizure_app/features/daily_log/widgets/daily_week_selector.dart';
// ignore_for_file: must_call_super
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/features/root/root_view.dart';
import 'package:seizure_app/features/home/view_models/home_view_model.dart';
import 'package:seizure_app/features/analytics/analytics_view.dart';
import 'package:seizure_app/features/analytics/view_models/analytics_view_model.dart';
import 'dart:ui' as ui;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/daily_log_dto.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/features/daily_log/daily_log_view.dart';
import 'package:seizure_app/features/daily_log/view_models/daily_log_view_model.dart';
import 'package:seizure_app/features/analytics/widgets/insights_calendar.dart';
import 'package:seizure_app/features/cycle/view_models/cycle_view_model.dart';
import 'package:seizure_app/features/cycle/widgets/cycle_entry_editor.dart';
import 'package:seizure_app/features/seizure_log/widgets/add_seizure_log_bottom_sheet.dart';
import 'package:seizure_app/features/seizure_log/view_models/seizure_log_view_model.dart';
import 'package:seizure_app/features/seizure_log/widgets/seizure_calendar_summary.dart';
import 'package:seizure_app/core/dtos/cycle_tracking_dto.dart';

class PreviewRoot extends RootViewModel {
  @override
  void onInit() {}
}

class PreviewHome extends HomeViewModel {
  PreviewHome(super.store);
  @override
  void onInit() {}
}

class Logs extends SeizureLogViewModel {
  Logs(super.store) : super(currentUid: () => 'owner');
  @override
  void onInit() {}
}

Future<DailyLogViewModel> fixture({
  bool populated = false,
  bool cycle = false,
}) async {
  final db = FakeFirebaseFirestore();
  await db.collection('users').doc('owner').set({
    'displayName': 'Fictional sample',
  });
  final store = FirestoreService(db);
  SharedPreferences.setMockInitialValues({});
  Get.put(AppModeService(await SharedPreferences.getInstance()));
  Get.put<RootViewModel>(PreviewRoot());
  final today = DateTime(2026, 10, 23);
  if (populated) {
    await store.saveDailyLog(
      'owner',
      DailyLogDto(
        date: today,
        sleepMinutes: 450,
        sleepQuality: 'fair',
        mood: 'neutral',
        stress: 'moderate',
        notes: 'Fictional demonstration entry',
      ),
    );
  }
  final daily = DailyLogViewModel(
    store,
    currentUid: () => 'owner',
    clock: () => today,
  );
  await daily.load();
  Get.put(daily);
  await daily.load();
  final logs = Get.put<SeizureLogViewModel>(Logs(store));
  logs.screenState.value = GenericScreenStates.loaded;
  if (populated) {
    logs.logs.add(
      SeizureLogDto(
        id: 'sample',
        userId: 'owner',
        occurredAt: DateTime(2026, 10, 23, 8, 15),
        durationSeconds: 45,
        seizureType: 'Tonic',
      ),
    );
  }
  if (cycle) {
    final vm = CycleViewModel(
      store,
      currentUid: () => 'owner',
      clock: () => today,
    );
    await vm.load();
    Get.put(vm);
    await vm.load();
    await vm.setEnabled(true);
    await vm.save(
      CycleEntryDto(
        id: 'period',
        start: DateTime(2026, 10, 20),
        flow: CycleFlow.light,
      ),
    );
  }
  final home = PreviewHome(store)
    ..screenState.value = GenericScreenStates.loaded;
  home.seizureLogs.assignAll(logs.logs);
  Get.put(AnalyticsViewModel(home, clock: () => today));
  return daily;
}

Widget app({bool dark = false, double scale = 1, Widget? child}) =>
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: SafeArea(child: child ?? const DailyLogView())),
    );
Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    maxScrolls: 90,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    Get.testMode = true;
  });
  tearDown(Get.reset);
  testWidgets(
    'daily check-in saves independently, date changes guard a draft',
    (tester) async {
      final vm = await fixture();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(SeizureCalendarSummary), findsNothing);
      await reveal(tester, find.widgetWithText(TextField, 'Sleep hours'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Sleep hours'),
        '7.5',
      );
      final change = vm.selectDate(DateTime(2026, 10, 22));
      await tester.pumpAndSettle();
      expect(find.text('Discard daily changes?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await change, false);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Sleep hours'))
            .controller!
            .text,
        '7.5',
      );
      await reveal(tester, find.text('Save daily entry'));
      await tester.tap(find.text('Save daily entry'));
      await tester.pumpAndSettle();
      expect(vm.entry.value!.sleepMinutes, 450);
      expect(vm.entry.value!.noSeizuresReported, false);
      expect(Get.find<SeizureLogViewModel>().logs, isEmpty);
      expect(await vm.selectDate(DateTime(2026, 10, 22)), true);
      await tester.pumpAndSettle();
      expect(vm.entry.value, isNull);
      await tester.drag(find.byType(ListView).first, const Offset(0, 1800));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add seizure'));
      await tester.pumpAndSettle();
      expect(find.byType(AddSeizureLogBottomSheet), findsOneWidget);
      expect(
        tester
            .widget<AddSeizureLogBottomSheet>(
              find.byType(AddSeizureLogBottomSheet),
            )
            .initialOccurredAt!
            .day,
        22,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Insights date selection returns to Daily log and protects drafts',
    (tester) async {
      final vm = await fixture();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await reveal(tester, find.widgetWithText(TextField, 'Sleep hours'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Sleep hours'),
        '8',
      );
      Get.to(() => const AnalyticsView());
      await tester.pumpAndSettle();
      final target = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == '2026-10-22',
      );
      await reveal(tester, target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.text('Discard daily changes?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(vm.selectedDate.value, DateTime(2026, 10, 23));
      expect(find.byType(AnalyticsView), findsOneWidget);
      await tester.tap(target);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(vm.selectedDate.value, DateTime(2026, 10, 22));
      expect(Get.find<RootViewModel>().currentIndex.value, 1);
      expect(find.byType(AnalyticsView), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'seizure entries override a no-seizure report and removal is confirmed',
    (tester) async {
      final vm = await fixture(populated: true);
      final result = await vm.store.saveDailyLog(
        'owner',
        DailyLogDto(date: vm.today, noSeizuresReported: true),
        expected: vm.entry.value,
      );
      expect(result.isSuccess, true);
      await vm.load();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('You reported no seizures for this day.'), findsNothing);
      expect(
        find.text('Seizure entries are recorded for this day.'),
        findsOneWidget,
      );
      await reveal(tester, find.text('Remove daily check-in'));
      await tester.tap(find.text('Remove daily check-in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(vm.entry.value, isNotNull);
      await tester.tap(find.text('Remove daily check-in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(vm.entry.value, isNull);
      expect(Get.find<SeizureLogViewModel>().logs, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'daily notes and save stay reachable above the keyboard and navigation inset',
    (tester) async {
      tester.view.physicalSize = const Size(280, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewInsets);
      await fixture();
      await tester.pumpWidget(app(scale: 3));
      await tester.pumpAndSettle();
      await reveal(tester, find.widgetWithText(TextField, 'Daily notes'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Daily notes'),
        'Fictional daily note',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Save daily entry'));
      expect(find.text('Save daily entry').hitTestable(), findsOneWidget);
      expect(
        tester.getBottomLeft(find.text('Save daily entry')).dy,
        lessThan(500),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('week swipes snap seven days and stay within the current week', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = await fixture();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final pager = find.byKey(const ValueKey('daily-week-pages'));
    await tester.drag(pager, const Offset(350, 0));
    await tester.pumpAndSettle();
    expect(vm.selectedDate.value, DateTime(2026, 10, 16));
    final controller = tester.widget<PageView>(pager).controller!;
    expect(controller.page, closeTo(controller.page!.roundToDouble(), 0.001));
    await tester.drag(pager, const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(vm.selectedDate.value, DateTime(2026, 10, 23));
    await tester.drag(pager, const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(vm.selectedDate.value, DateTime(2026, 10, 23));
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == 'Next week',
            ),
          )
          .onPressed,
      isNull,
    );
    await vm.selectDate(DateTime(2025, 12, 31));
    await tester.pumpAndSettle();
    await tester.drag(pager, const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(vm.selectedDate.value, DateTime(2026, 1, 7));
    expect(tester.takeException(), isNull);
  });
  testWidgets('cancelled week swipe snaps back and retains the daily draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = await fixture();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await reveal(tester, find.widgetWithText(TextField, 'Sleep hours'));
    await tester.enterText(find.widgetWithText(TextField, 'Sleep hours'), '8');
    tester.testTextInput.hide();
    await tester.drag(find.byType(ListView).first, const Offset(0, 1500));
    await tester.pumpAndSettle();
    final pager = find.byKey(const ValueKey('daily-week-pages'));
    final originalPage = tester.widget<PageView>(pager).controller!.page!;
    await tester.drag(pager, const Offset(350, 0));
    await tester.pumpAndSettle();
    expect(find.text('Discard daily changes?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(vm.selectedDate.value, DateTime(2026, 10, 23));
    expect(
      tester.widget<PageView>(pager).controller!.page,
      closeTo(originalPage, 0.001),
    );
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Sleep hours'))
          .controller!
          .text,
      '8',
    );
    await tester.tap(find.byTooltip('Previous week'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(vm.selectedDate.value, DateTime(2026, 10, 16));
    expect(tester.takeException(), isNull);
  });
  test(
    'week boundaries use civil Mondays across year and leap-day boundaries',
    () {
      expect(dailyWeekStart(DateTime(2026, 1, 1)), DateTime(2025, 12, 29));
      expect(dailyWeekStart(DateTime(2024, 2, 29)), DateTime(2024, 2, 26));
      expect(dailyWeekStart(DateTime(1900, 1, 1)), DateTime(1900, 1, 1));
    },
  );
  testWidgets('optional cycle editor starts on the selected date', (
    tester,
  ) async {
    final vm = await fixture(cycle: true);
    await vm.selectDate(DateTime(2026, 10, 18));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Add period / spotting'));
    await tester.tap(find.text('Add period / spotting'));
    await tester.pumpAndSettle();
    final editor = tester.widget<CycleEntryEditor>(
      find.byType(CycleEntryEditor),
    );
    expect(editor.initialDate, DateTime(2026, 10, 18));
    expect(tester.takeException(), isNull);
  });
  for (final dark in [false, true]) {
    for (final scale in [1.0, 3.0]) {
      testWidgets('daily and calendar at width 280 scale=$scale dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await fixture(populated: true, cycle: true);
        await tester.pumpWidget(app(dark: dark, scale: scale));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Save daily entry'));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          app(
            dark: dark,
            scale: scale,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                InsightsCalendar(
                  logs: Get.find<SeizureLogViewModel>().logs.toList(),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('1 day recorded. Unrecorded days are excluded.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('capture daily and insights dark=$dark', (tester) async {
      if (!const bool.fromEnvironment('DAILY_PREVIEW')) {
        return;
      }
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await fixture(populated: true, cycle: true);
      await tester.runAsync(() async {
        await (FontLoader('RedHatDisplay')
              ..addFont(
                rootBundle.load('assets/fonts/RedHatDisplay-Regular.ttf'),
              )
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
      Future<void> capture(String name) async => tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'docs/design/$name-${dark ? 'dark' : 'light'}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: app(dark: dark),
        ),
      );
      await tester.pumpAndSettle();
      await capture('daily-log');
      await reveal(tester, find.widgetWithText(TextField, 'Daily notes'));
      await capture('daily-check-in');
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: GetMaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: const AnalyticsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capture('insights-calendar');
      expect(tester.takeException(), isNull);
    });
  }
}
