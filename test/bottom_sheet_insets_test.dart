import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';

void main() {
  for (final navigationInset in [0.0, 24.0, 48.0]) {
    for (final scrollable in [true, false]) {
      testWidgets(
        'drawer clears system inset $navigationInset scrollable=$scrollable and keyboard changes',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          tester.view.viewPadding = FakeViewPadding(bottom: navigationInset);
          tester.view.padding = FakeViewPadding(bottom: navigationInset);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPadding);
          addTearDown(tester.view.resetViewPadding);
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => AppBottomSheet.show<void>(
                      context: context,
                      builder: (_) => AppBottomSheetContent(
                        scrollable: scrollable,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Edit Contact'),
                            const TextField(),
                            ElevatedButton(
                              onPressed: () {},
                              child: const Text('Save Changes'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: const Text('Open drawer'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open drawer'));
          await tester.pumpAndSettle();
          final save = find.widgetWithText(ElevatedButton, 'Save Changes');
          for (final keyboard in [0.0, 300.0, 0.0]) {
            tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
            tester.view.padding = FakeViewPadding(
              bottom: keyboard == 0 ? navigationInset : 0,
            );
            await tester.pumpAndSettle();
            if (scrollable) {
              await tester.ensureVisible(save);
              await tester.pumpAndSettle();
            }
            expect(
              tester.getRect(save).bottom,
              lessThanOrEqualTo(
                844 - (keyboard > 0 ? keyboard : navigationInset) - 24,
              ),
            );
            expect(save.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }
}
