import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';
import 'package:seizure_app/features/sos/widgets/sos_button_widget.dart';

import '../support/pump.dart';

void main() {
  testWidgets('SOS exposes one labelled action with a full tap target', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(wrap(SOSButton(onPressed: () {})));

    expect(find.bySemanticsLabel('Send SOS alert'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('settings actions meet tap-target and label guidelines', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      wrap(
        SettingsGroup(
          children: <Widget>[
            SettingsNavRow(
              icon: Icons.help_outline,
              title: 'Help & diagnostics',
              onTap: () {},
            ),
          ],
        ),
      ),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
