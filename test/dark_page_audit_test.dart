import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/core/services/caregiver_service.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/core/widgets/app_wordmark.dart';
import 'package:seizure_app/features/mode/mode_view.dart';
import 'package:seizure_app/features/mode/view_models/mode_view_model.dart';
import 'package:seizure_app/features/sos/view_models/sos_view_model.dart';
import 'package:seizure_app/features/sos/widgets/sos_status_board_header.dart';
import 'package:seizure_app/features/sos/widgets/sos_button_widget.dart';

class _Caregiver extends Fake implements CaregiverService {}

double _contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05);
}

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(Get.reset);

  for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
    testWidgets('SOS countdown stays dark and legible in ${theme.brightness}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: CountdownAlertDialog(onConfirm: () {}, onCancel: () {}),
          ),
        ),
      );
      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      final count = tester.widget<Text>(find.text('10'));
      expect(dialog.backgroundColor!.computeLuminance(), lessThan(0.05));
      expect(
        _contrast(count.style!.color!, dialog.backgroundColor!),
        greaterThanOrEqualTo(4.5),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Mode page and sign-in wordmark follow ${theme.brightness}', (
      tester,
    ) async {
      Get.put(
        ModeViewModel(
          AppModeService(await SharedPreferences.getInstance()),
          _Caregiver(),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(theme: theme, home: const ModeView()),
      );
      await tester.pump();
      final page = tester.widget<Material>(find.byType(Material).first);
      expect(page.color, theme.scaffoldBackgroundColor);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: AppWordmark()),
        ),
      );
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(AppWordmark),
          matching: find.byType(Text),
        ),
      );
      expect(
        _contrast(text.style!.color!, theme.scaffoldBackgroundColor),
        greaterThanOrEqualTo(4.5),
      );
      expect(tester.takeException(), isNull);
    });

    for (final delivery in [SosDelivery.failed, SosDelivery.queued]) {
      testWidgets(
        'SOS call action and cancellation dialog retain contrast ${theme.brightness} $delivery',
        (tester) async {
          var cancelled = false;
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: SosStatusBoardHeader(
                  elapsedLabel: '00:30',
                  seenCount: 0,
                  totalCount: 1,
                  onCancel: () => cancelled = true,
                  delivery: delivery,
                  onCallForHelp: () {},
                ),
              ),
            ),
          );
          final call = tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Call a contact instead'),
          );
          final background = call.style!.backgroundColor!.resolve({})!;
          final foreground = call.style!.foregroundColor!.resolve({})!;
          expect(_contrast(foreground, background), greaterThanOrEqualTo(4.5));
          await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
          await tester.pumpAndSettle();
          final dialogMaterial = tester.widget<Material>(
            find
                .descendant(
                  of: find.byType(Dialog),
                  matching: find.byType(Material),
                )
                .first,
          );
          expect(dialogMaterial.color, theme.dialogTheme.backgroundColor);
          expect(
            _contrast(
              theme.textTheme.titleMedium!.color!,
              dialogMaterial.color!,
            ),
            greaterThanOrEqualTo(4.5),
          );
          await tester.tap(find.text('Keep alert active'));
          await tester.pumpAndSettle();
          expect(cancelled, isFalse);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
