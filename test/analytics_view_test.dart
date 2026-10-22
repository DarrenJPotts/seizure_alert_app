// ignore_for_file: must_call_super
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/features/analytics/analytics_view.dart';
import 'package:seizure_app/features/analytics/view_models/analytics_view_model.dart';
import 'package:seizure_app/features/home/view_models/home_view_model.dart';

class _Firestore extends Fake implements FirestoreService {}

class _Home extends HomeViewModel {
  _Home() : super(_Firestore());
  @override
  void onInit() {}
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);
  for (final dark in [false, true]) {
    testWidgets('render Insights preview dark=$dark', (tester) async {
      if (!const bool.fromEnvironment('ANALYTICS_PREVIEW')) return;
      final oldShadows = debugDisableShadows;
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = oldShadows);
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
      final home = _Home()..screenState.value = GenericScreenStates.loaded;
      final now = DateTime(2026, 10, 21, 12);
      home.seizureLogs.assignAll([
        for (var i = 0; i < 12; i++)
          SeizureLogDto(
            id: '$i',
            userId: 'preview',
            occurredAt: DateTime(2026, 10, 20 - i * 3, i % 2 == 0 ? 8 : 19),
            durationSeconds: i % 4 == 0 ? null : 45 + i * 5,
            recoveryMinutes: i % 3 == 0 ? null : 10 + i,
          ),
      ]);
      Get.put(AnalyticsViewModel(home, clock: () => now));
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: const AnalyticsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> capture(String section) async {
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final snapshot = await boundary.toImage(pixelRatio: 2);
          final bytes = (await snapshot.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          await Directory('docs/design').create(recursive: true);
          await File(
            'docs/design/insights-${dark ? 'dark' : 'light'}-$section.png',
          ).writeAsBytes(bytes.buffer.asUint8List());
          snapshot.dispose();
        });
      }

      await capture('overview');
      await tester.scrollUntilVisible(find.text('Duration'), 300);
      await tester.pumpAndSettle();
      await capture('details');
      debugDisableShadows = oldShadows;
      home.onClose();
    });
  }
  for (final dark in [false, true]) {
    for (final scale in [1.0, 3.0]) {
      testWidgets(
        'Insights narrow layout dark=$dark scale=$scale updates periods and entries',
        (tester) async {
          tester.view.physicalSize = const Size(280, 560);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final home = _Home()..screenState.value = GenericScreenStates.loaded;
          final now = DateTime(2026, 10, 21, 12);
          home.seizureLogs.assignAll([
            SeizureLogDto(
              id: 'one',
              userId: 'user',
              occurredAt: now,
              durationSeconds: 60,
              recoveryMinutes: 10,
            ),
          ]);
          final vm = Get.put(AnalyticsViewModel(home, clock: () => now));
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: const AnalyticsView(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(vm.summary.count, 1);
          final period = find.widgetWithText(ChoiceChip, '90 days');
          for (
            var attempt = 0;
            attempt < 50 && period.hitTestable().evaluate().isEmpty;
            attempt++
          ) {
            await tester.drag(find.byType(ListView), const Offset(0, -150));
            await tester.pumpAndSettle();
          }
          await tester.tap(period.hitTestable());
          await tester.pumpAndSettle();
          expect(vm.selectedDays.value, 90);
          await tester.scrollUntilVisible(
            find.text('Recovery'),
            300,
            maxScrolls: 60,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.text('Time of day'),
            300,
            maxScrolls: 60,
          );
          await tester.pumpAndSettle();
          home.seizureLogs.clear();
          await tester.pumpAndSettle();
          expect(vm.summary.count, 0);
          await tester.scrollUntilVisible(
            find.textContaining('No events recorded in this period.'),
            -300,
            maxScrolls: 60,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          home.onClose();
        },
      );
    }
  }
}
