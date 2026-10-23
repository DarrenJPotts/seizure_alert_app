import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/core/widgets/duration_stepper_field.dart';
import 'package:seizure_app/features/seizure_log/widgets/add_seizure_log_bottom_sheet.dart';

void main() {
  for (final existingSeconds in <int?>[null, 119, 6000]) {
    testWidgets(
      'entry duration preserves and saves seconds: $existingSeconds',
      (tester) async {
        int? savedSeconds;
        String? savedId;
        var saves = 0;
        Future<bool> save({
          String? id,
          required DateTime occurredAt,
          int? durationSeconds,
          String? location,
          String? trigger,
          String? notes,
          String? seizureType,
          String? aura,
          String? severity,
          String? awareness,
          String? injuries,
          int? recoveryMinutes,
          bool rescueMedicationUsed = false,
          bool alertFired = false,
        }) async {
          savedSeconds = durationSeconds;
          savedId = id;
          saves++;
          return false;
        }

        final log = existingSeconds == null
            ? null
            : SeizureLogDto(
                id: 'entry',
                userId: 'user',
                occurredAt: DateTime(2026, 10, 19),
                durationSeconds: existingSeconds,
              );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AddSeizureLogBottomSheet(
                onAdd: save,
                onUpdate: save,
                existingLog: log,
              ),
            ),
          ),
        );
        final minutes = find.byKey(const ValueKey('entry-duration-minutes'));
        final seconds = find.byKey(const ValueKey('entry-duration-seconds'));
        expect(
          tester.widget<DurationStepperField>(minutes).value,
          (existingSeconds ?? 0) ~/ 60,
        );
        expect(
          tester.widget<DurationStepperField>(seconds).value,
          (existingSeconds ?? 0) % 60,
        );
        final saveButton = find.widgetWithText(
          ElevatedButton,
          log == null ? 'Save Entry' : 'Save Changes',
        );
        Future<void> persist() async {
          await tester.ensureVisible(saveButton);
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
          ScaffoldMessenger.of(
            tester.element(saveButton),
          ).removeCurrentSnackBar();
          await tester.pumpAndSettle();
        }

        await persist();
        expect(saves, 1);
        expect(savedSeconds, existingSeconds);
        expect(savedId, log?.id);
        final tooltip = existingSeconds == null
            ? 'Increase seconds'
            : 'Decrease seconds';
        if (existingSeconds == 6000) {
          await tester.ensureVisible(find.byTooltip('Decrease minutes'));
          await tester.tap(find.byTooltip('Decrease minutes'));
        } else {
          await tester.ensureVisible(find.byTooltip(tooltip));
          await tester.tap(find.byTooltip(tooltip));
        }
        await tester.pump();
        await persist();
        expect(saves, 2);
        expect(
          savedSeconds,
          existingSeconds == null
              ? 1
              : existingSeconds == 6000
              ? 5940
              : 118,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
