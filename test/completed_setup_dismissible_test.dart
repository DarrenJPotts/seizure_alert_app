import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/features/home/widgets/completed_setup_dismissible.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  for (final direction in [-1.0, 1.0]) {
    testWidgets('completed setup hides by swiping $direction and persists', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      final mode = AppModeService(prefs);
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Obx(
              () => mode.hideCompletedSetup.value
                  ? const SizedBox.shrink()
                  : CompletedSetupDismissible(
                      enabled: true,
                      onDismissed: () => mode.setHideCompletedSetup(true),
                      child: SizedBox(
                        height: 120,
                        child: InkWell(
                          onTap: () => taps++,
                          child: const Center(child: Text('Setup check')),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.close), findsNothing);
      await tester.drag(find.text('Setup check'), Offset(direction * 800, 0));
      await tester.pumpAndSettle();
      expect(find.text('Setup check'), findsNothing);
      expect(AppModeService(prefs).hideCompletedSetup.value, isTrue);
      expect(taps, 0);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('incomplete setup remains visible after swiping', (tester) async {
    var hidden = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompletedSetupDismissible(
            enabled: false,
            onDismissed: () => hidden = true,
            child: const SizedBox(
              height: 120,
              child: Center(child: Text('Notifications disabled')),
            ),
          ),
        ),
      ),
    );
    await tester.drag(
      find.text('Notifications disabled'),
      const Offset(-800, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Notifications disabled'), findsOneWidget);
    expect(hidden, isFalse);
    expect(find.byType(Dismissible), findsNothing);
  });
}
