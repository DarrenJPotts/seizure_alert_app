import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';

void main() {
  testWidgets(
    'navigation rows wrap long labels and values at large text sizes',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 280,
                child: MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: SettingsNavRow(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Safety plan and medication reminders',
                    trailingText: 'Many reminders configured',
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final label = tester.getRect(
        find.text('Safety plan and medication reminders'),
      );
      final value = tester.getRect(find.text('Many reminders configured'));
      expect(value.top, greaterThanOrEqualTo(label.bottom));
    },
  );
}
