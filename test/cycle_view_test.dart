import 'package:seizure_app/features/daily_log/view_models/daily_log_view_model.dart';
// ignore_for_file: must_call_super
import 'dart:io';
import 'dart:ui' as ui;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/cycle_tracking_dto.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/features/cycle/cycle_view.dart';
import 'package:seizure_app/features/cycle/view_models/cycle_view_model.dart';
import 'package:seizure_app/features/cycle/widgets/cycle_entry_editor.dart';
import 'package:seizure_app/features/seizure_log/seizure_log_view.dart';
import 'package:seizure_app/features/seizure_log/view_models/seizure_log_view_model.dart';

class _Logs extends SeizureLogViewModel {
  _Logs(super.store) : super(currentUid: () => 'owner');
  @override
  void onInit() {}
}

Future<CycleViewModel> fixture({
  bool enabled = true,
  bool entries = true,
}) async {
  final db = FakeFirebaseFirestore();
  await db
      .collection('users')
      .doc('owner')
      .set(UserDto(uid: 'owner', email: 'fictional@example.test').toMap());
  final store = FirestoreService(db);
  final vm = CycleViewModel(
    store,
    currentUid: () => 'owner',
    clock: () => DateTime(2026, 10, 23),
  );
  await vm.load();
  if (enabled) await vm.setEnabled(true);
  if (enabled && entries) {
    await vm.save(
      CycleEntryDto(
        id: 'period',
        start: DateTime(2026, 10, 14),
        end: DateTime(2026, 10, 18),
        flow: CycleFlow.medium,
        symptoms: 'Cramps',
        notes: 'Fictional sample entry',
      ),
    );
  }
  final daily = DailyLogViewModel(
    store,
    currentUid: () => 'owner',
    clock: () => DateTime(2026, 10, 23),
  );
  await daily.load();
  Get.put<DailyLogViewModel>(daily);
  Get.put<CycleViewModel>(vm);
  final logs = Get.put<SeizureLogViewModel>(_Logs(store));
  logs.screenState.value = GenericScreenStates.loaded;
  logs.logs.assignAll([
    SeizureLogDto(
      id: 'seizure',
      userId: 'owner',
      occurredAt: DateTime(2026, 10, 16, 10),
      durationSeconds: 40,
      seizureType: 'Tonic',
    ),
  ]);
  return vm;
}

Widget app({bool dark = false, double scale = 1, Widget? home}) =>
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          viewPadding: const EdgeInsets.only(bottom: 48),
          padding: const EdgeInsets.only(bottom: 48),
        ),
        child: child!,
      ),
      home: home ?? const CycleView(),
    );
void main() {
  setUp(() {
    Get.testMode = true;
  });
  tearDown(Get.reset);
  testWidgets('cycle tracking requires informed opt-in and can add an entry', (
    tester,
  ) async {
    final vm = await fixture(enabled: false);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Period entries'), findsNothing);
    await tester.tap(find.text('Cycle tracking'));
    await tester.pumpAndSettle();
    expect(find.text('Enable cycle tracking?'), findsOneWidget);
    expect(vm.data.value.enabled, isFalse);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(vm.data.value.enabled, isFalse);
    await tester.tap(find.text('Cycle tracking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable'));
    await tester.pumpAndSettle();
    expect(vm.data.value.enabled, isTrue);
    await tester.tap(find.byTooltip('Add period entry'));
    await tester.pumpAndSettle();
    expect(find.byType(CycleEntryEditor), findsOneWidget);
    await tester.ensureVisible(find.text('Save entry'));
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();
    expect(vm.data.value.entries, hasLength(1));
    expect(vm.data.value.entries.single.end, isNull);
  });
  testWidgets('report inclusion is unchecked every time', (tester) async {
    await fixture();
    await tester.pumpWidget(app(home: const Scaffold(body: SeizureLogView())));
    await tester.pumpAndSettle();
    for (var index = 0; index < 2; index++) {
      await tester.tap(find.byTooltip('Share clinical report'));
      await tester.pumpAndSettle();
      final checkbox = find.widgetWithText(
        CheckboxListTile,
        'Include cycle data',
      );
      expect(tester.widget<CheckboxListTile>(checkbox).value, isFalse);
      await tester.tap(checkbox);
      await tester.pump();
      expect(tester.widget<CheckboxListTile>(checkbox).value, isTrue);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }
  });
  for (final dark in [false, true]) {
    for (final scale in [1.0, 3.0]) {
      testWidgets('private calendar/editor width=280 text=$scale dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await fixture();
        await tester.pumpWidget(app(dark: dark, scale: scale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Add period entry'));
        await tester.pumpAndSettle();
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Save entry'));
        await tester.pumpAndSettle();
        expect(find.text('Save entry').hitTestable(), findsOneWidget);
        expect(
          tester.getBottomLeft(find.text('Save entry')).dy,
          lessThan(800 - 300),
        );
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        Navigator.of(tester.element(find.byType(CycleEntryEditor))).pop();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Delete all cycle data'),
          250,
          maxScrolls: 60,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Delete all cycle data'));
        await tester.drag(find.byType(ListView).first, const Offset(0, -150));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete all cycle data'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(Get.find<CycleViewModel>().data.value.entries, hasLength(1));
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('render cycle preview dark=$dark', (tester) async {
      if (!const bool.fromEnvironment('CYCLE_PREVIEW')) return;
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await fixture();
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
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: app(dark: dark),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      Future<void> capture(String suffix) async => tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'docs/design/cycle-${dark ? 'dark' : 'light'}-$suffix.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await capture('overview');
      await tester.tap(find.byTooltip('Add period entry'));
      await tester.pumpAndSettle();
      await capture('editor');
    });
  }
}
