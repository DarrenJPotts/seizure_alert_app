import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/features/heads_up/heads_up/heads_up_bottom_sheet_widget.dart';
import 'package:seizure_app/features/heads_up/view_models/heads_up_view_model.dart';
import 'package:seizure_app/features/sos/widgets/sos_idle_sheet.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:seizure_app/core/themes/app_theme.dart';

void main() {
  testWidgets('time picker is compact on phones and retains full tap targets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = HeadsUpViewModel();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: HeadsUpBottomSheet(customDuration: true, viewModel: vm),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('heads-up-hours'))).height,
      lessThan(90),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('heads-up-minutes'))).height,
      lessThan(90),
    );
    for (final button in find.byType(IconButton).evaluate()) {
      final size = tester.getSize(find.byWidget(button.widget));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    vm.onClose();
  });

  for (final reducedMotion in [false, true]) {
    testWidgets(
      'pull or tap opens the main Heads Up drawer once, reducedMotion=$reducedMotion',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        tester.view.viewPadding = const FakeViewPadding(bottom: 48);
        tester.view.padding = const FakeViewPadding(bottom: 48);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        final vm = HeadsUpViewModel(currentUid: () => null);
        addTearDown(vm.onClose);
        var opens = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: MediaQueryData(
                padding: const EdgeInsets.only(bottom: 48),
                viewPadding: const EdgeInsets.only(bottom: 48),
                disableAnimations: reducedMotion,
              ),
              child: Scaffold(
                body: Builder(
                  builder: (context) => SosIdleSheet(
                    sheetMinSize: 0.1,
                    sheetMaxSize: 0.55,
                    sosHero: const Text('SOS'),
                    content: const Text('Intermediate duration card'),
                    onOpenHeadsUp: () async {
                      opens++;
                      await AppBottomSheet.show<void>(
                        context: context,
                        builder: (_) => HeadsUpBottomSheet(viewModel: vm),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        for (final action in ['pull', 'tap', 'pull']) {
          final toggle = find.byKey(const ValueKey('heads-up-sheet-toggle'));
          if (action == 'pull') {
            await tester.drag(toggle, const Offset(0, -120));
          } else {
            await tester.tap(toggle);
          }
          await tester.pumpAndSettle();
          expect(find.byType(HeadsUpBottomSheet), findsOneWidget);
          expect(find.text('Intermediate duration card'), findsNothing);
          expect(
            opens,
            action == 'pull' && opens == 1
                ? 1
                : action == 'tap'
                ? 2
                : 3,
          );
          final send = find.widgetWithText(ElevatedButton, 'Send Heads Up');
          await tester.ensureVisible(send);
          await tester.pumpAndSettle();
          expect(tester.getRect(send).bottom, lessThanOrEqualTo(844 - 48 - 24));
          Navigator.of(tester.element(find.byType(HeadsUpBottomSheet))).pop();
          await tester.pumpAndSettle();
          final sheet = tester.widget<DraggableScrollableSheet>(
            find.byType(DraggableScrollableSheet),
          );
          expect(sheet.controller!.size, closeTo(sheet.minChildSize, 0.001));
          expect(find.byType(HeadsUpBottomSheet), findsNothing);
          expect(vm.activeHeadsUp.value, isNull);
          expect(tester.takeException(), isNull);
        }
        expect(opens, 3);
      },
    );
  }

  for (final minutes in [1, 45, 90, 1440]) {
    test(
      'allows custom $minutes minute duration',
      () => expect(HeadsUpViewModel.isValidDuration(minutes), isTrue),
    );
  }
  for (final minutes in [0, -1, 1441]) {
    test(
      'rejects $minutes minute duration',
      () => expect(HeadsUpViewModel.isValidDuration(minutes), isFalse),
    );
  }
  testWidgets(
    'custom hours and minutes preserve selection and enforce limits',
    (tester) async {
      final vm = HeadsUpViewModel()..selectedMinutes.value = 90;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeadsUpBottomSheet(customDuration: true, viewModel: vm),
          ),
        ),
      );
      expect(find.text('01'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text(':'), findsOneWidget);
      Future<void> tap(String tooltip) async {
        await tester.tap(find.byTooltip(tooltip));
        await tester.pump();
      }

      bool enabled(String tooltip) =>
          tester
              .widget<IconButton>(
                find.byWidgetPredicate(
                  (widget) => widget is IconButton && widget.tooltip == tooltip,
                ),
              )
              .onPressed !=
          null;
      await tap('Increase hours');
      expect(vm.selectedMinutes.value, 150);
      await tap('Increase minutes');
      expect(vm.selectedMinutes.value, 151);
      await tap('Decrease minutes');
      expect(vm.selectedMinutes.value, 150);
      vm.selectedMinutes.value = 1439;
      await tester.pump();
      await tap('Increase hours');
      expect(vm.selectedMinutes.value, 1440);
      expect(enabled('Increase hours'), isFalse);
      expect(enabled('Increase minutes'), isFalse);
      expect(enabled('Decrease minutes'), isFalse);
      await tap('Decrease hours');
      expect(vm.selectedMinutes.value, 1380);
      vm.selectedMinutes.value = 0;
      await tester.pump();
      expect(enabled('Decrease hours'), isFalse);
      expect(enabled('Decrease minutes'), isFalse);
      expect(find.text('Select at least 1 minute.'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      await tap('Increase minutes');
      expect(vm.selectedMinutes.value, 1);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
      vm.selectedMinutes.value = 59;
      await tester.pump();
      expect(enabled('Increase minutes'), isFalse);
      await tester.ensureVisible(find.text('30 min'));
      await tester.tap(find.text('30 min'));
      await tester.pump();
      expect(vm.selectedMinutes.value, 30);
      expect(find.byKey(const ValueKey('heads-up-hours')), findsNothing);
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      vm.onClose();
    },
  );
  for (final reducedMotion in [false, true]) {
    testWidgets(
      'Heads Up supports tap and semantic toggle reducedMotion=$reducedMotion',
      (tester) async {
        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reducedMotion),
              child: const Scaffold(
                body: SosIdleSheet(
                  sheetMinSize: 0.1,
                  sheetMaxSize: 0.55,
                  sosHero: Text('SOS'),
                  content: Text('Heads Up controls'),
                ),
              ),
            ),
          ),
        );
        final toggle = find.byKey(const ValueKey('heads-up-sheet-toggle'));
        expect(tester.widget<Semantics>(toggle).properties.value, 'Collapsed');
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.text('Heads Up controls'), findsOneWidget);
        expect(tester.widget<Semantics>(toggle).properties.value, 'Expanded');
        tester.widget<Semantics>(toggle).properties.onTap!();
        await tester.pumpAndSettle();
        expect(find.text('Heads Up controls'), findsNothing);
        expect(
          tester
              .widget<DraggableScrollableSheet>(
                find.byType(DraggableScrollableSheet),
              )
              .controller!
              .size,
          closeTo(0.1, 0.001),
        );
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets(
      'short SOS layout keeps Heads Up heading above bottom controls at $scale scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 560);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const Scaffold(
                body: SosIdleSheet(
                  sheetMinSize: 0.1,
                  sheetMaxSize: 0.55,
                  sosHero: SizedBox(
                    height: 420,
                    child: Center(child: Text('SOS')),
                  ),
                  content: SizedBox(
                    height: 240,
                    child: Text('Heads Up controls'),
                  ),
                ),
                bottomNavigationBar: SizedBox(height: 122),
              ),
            ),
          ),
        );
        await tester.pump();
        final heading = find.byKey(const ValueKey('heads-up-sheet-heading'));
        final bounds = tester.getRect(heading);
        expect(bounds.bottom, lessThanOrEqualTo(560 - 122));
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(tester.takeException(), isNull);
        await tester.drag(heading, const Offset(0, -180));
        await tester.pumpAndSettle();
        expect(find.text('Heads Up controls'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
