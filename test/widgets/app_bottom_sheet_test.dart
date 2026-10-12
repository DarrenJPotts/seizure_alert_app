import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';

void main() {
  testWidgets('drag handle stays outside the scroll view and dismisses sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: TextButton(
              onPressed: () => AppBottomSheet.show<void>(
                context: context,
                builder: (_) => AppBottomSheetContent(
                  child: Column(
                    children: List<Widget>.generate(
                      30,
                      (int index) => Text('Field $index'),
                    ),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final Finder handle = find.byType(AppBottomSheetHandle);
    expect(handle, findsOneWidget);
    expect(
      find.ancestor(of: handle, matching: find.byType(SingleChildScrollView)),
      findsNothing,
    );

    await tester.drag(handle, const Offset(0, 600));
    await tester.pumpAndSettle();

    expect(find.text('Field 0'), findsNothing);
  });
}
