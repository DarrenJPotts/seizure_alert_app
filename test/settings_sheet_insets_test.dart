import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seizure_app/core/controllers/theme_controller/theme_controller.dart';
import 'package:seizure_app/core/themes/app_design.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/core/widgets/appearance_sheet.dart';
import 'package:seizure_app/core/widgets/design_style_sheet.dart';
import 'package:seizure_app/features/sos/widgets/sos_idle_sheet.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(Get.reset);

  test(
    'Soft editorial is the fresh-install and normal-release default',
    () async {
      final prefs = await SharedPreferences.getInstance();
      expect(
        ThemeController(prefs).resolvedDesign,
        AppDesignStyle.softEditorial,
      );
      expect(
        ThemeController(prefs, designSwitcherEnabled: false).resolvedDesign,
        AppDesignStyle.softEditorial,
      );
    },
  );

  for (final inset in [0.0, 24.0, 48.0]) {
    for (final designPicker in [false, true]) {
      testWidgets(
        'settings drawer clears navigation=$inset design=$designPicker through keyboard changes',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          tester.view.viewPadding = FakeViewPadding(
            bottom: inset,
            left: 16,
            right: 16,
          );
          tester.view.padding = FakeViewPadding(
            bottom: inset,
            left: 16,
            right: 16,
          );
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPadding);
          addTearDown(tester.view.resetViewPadding);
          addTearDown(tester.view.resetViewInsets);
          Get.put(ThemeController(await SharedPreferences.getInstance()));
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: designPicker
                    ? Builder(
                        builder: (context) => TextButton(
                          onPressed: () => DesignStyleSheet.show(context),
                          child: const Text('Open'),
                        ),
                      )
                    : const AppearanceSettingsRow(),
              ),
            ),
          );
          await tester.tap(find.text(designPicker ? 'Open' : 'Appearance'));
          await tester.pumpAndSettle();
          for (final keyboard in [0.0, 300.0, 0.0]) {
            tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
            tester.view.padding = FakeViewPadding(
              bottom: keyboard == 0 ? inset : 0,
              left: 16,
              right: 16,
            );
            await tester.pumpAndSettle();
            final done = find.widgetWithText(OutlinedButton, 'Done');
            await tester.ensureVisible(done);
            await tester.pumpAndSettle();
            final rect = tester.getRect(done);
            expect(
              rect.bottom,
              lessThanOrEqualTo(
                844 - (keyboard > inset ? keyboard : inset) - 24,
              ),
            );
            expect(rect.left, greaterThanOrEqualTo(16 + 24));
            expect(rect.right, lessThanOrEqualTo(390 - 16 - 24));
            expect(done.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
        },
      );
    }

    testWidgets('expanded Heads Up drawer clears navigation=$inset', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = FakeViewPadding(bottom: inset);
      tester.view.padding = FakeViewPadding(bottom: inset);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SosIdleSheet(
              sosHero: const Text('SOS'),
              sheetMinSize: 0.12,
              sheetMaxSize: 0.9,
              content: Column(
                children: [
                  for (var i = 0; i < 20; i++) Text('Content $i'),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Check in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('heads-up-sheet-toggle')));
      await tester.pumpAndSettle();
      final action = find.widgetWithText(ElevatedButton, 'Check in');
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(action).bottom,
        lessThanOrEqualTo(844 - inset - 24),
      );
      expect(action.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
