import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/features/heads_up/heads_up/heads_up_bottom_sheet_widget.dart';
import 'package:seizure_app/features/heads_up/view_models/heads_up_view_model.dart';
import 'package:seizure_app/features/sos/widgets/sos_idle_sheet.dart';

void main() {
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
  testWidgets('custom minutes update selection and disable send when invalid', (
    tester,
  ) async {
    final vm = HeadsUpViewModel();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeadsUpBottomSheet(customDuration: true, viewModel: vm),
        ),
      ),
    );
    final input = find.widgetWithText(TextField, 'Check-in duration (minutes)');
    await tester.enterText(input, '45');
    await tester.pump();
    expect(vm.selectedMinutes.value, 45);
    await tester.enterText(input, '1441');
    await tester.pump();
    expect(find.text('Enter 1 to 1,440 minutes.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Send Heads Up'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(
      find.text('30 min'),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('30 min'));
    await tester.pump();
    expect(vm.selectedMinutes.value, 30);
    expect(find.text('Check-in duration (minutes)'), findsNothing);
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    vm.onClose();
  });
  for (final scale in [1.0, 2.0]) {
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
              child: Scaffold(
                body: const SosIdleSheet(
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
                bottomNavigationBar: const SizedBox(height: 122),
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
