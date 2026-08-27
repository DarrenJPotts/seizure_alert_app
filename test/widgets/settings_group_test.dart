import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';
import 'package:seizure_app/core/widgets/settings/settings_screen_header.dart';

import '../support/pump.dart';

/// The grouped-card language shared by Mode, Profile and Seizure Log.
///
/// Worth covering because three screens now depend on these: a change made for
/// one silently reshapes the other two.
void main() {
  group('SettingsGroup', () {
    testWidgets('draws a hairline between children but not above the first', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          const SettingsGroup(
            children: <Widget>[
              SettingsMessageRow('one'),
              SettingsMessageRow('two'),
              SettingsMessageRow('three'),
            ],
          ),
        ),
      );

      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('a single child gets no dividers', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const SettingsGroup(children: <Widget>[SettingsMessageRow('only')])));

      expect(find.byType(Divider), findsNothing);
    });
  });

  group('SettingsValueRow', () {
    testWidgets('shows a chevron only when tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          const SettingsGroup(
            children: <Widget>[
              SettingsValueRow(icon: Icons.phone_outlined, label: 'Phone', value: 'Not set'),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.chevron_right), findsNothing);

      await tester.pumpWidget(
        wrap(
          SettingsGroup(
            children: <Widget>[
              SettingsValueRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: 'Not set',
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('grows past the base height for a multi-line value', (WidgetTester tester) async {
      // The emergency note is the field a caregiver reads mid-emergency. The
      // old fixed-width label column truncated it; this row must let it wrap.
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 360,
            child: SettingsGroup(
              children: <Widget>[
                SettingsValueRow(
                  icon: Icons.note_outlined,
                  label: 'Emergency note',
                  value: 'Do not restrain. Time the seizure. Over five minutes, give midazolam and call 10177.',
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(SettingsValueRow)).height, greaterThan(64));
      expect(tester.takeException(), isNull);
    });
  });

  group('SettingsTileRow', () {
    testWidgets('collapses to one semantics node when given a label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        wrap(
          SettingsTileRow(
            title: 'Today, 9:30 AM',
            subtitle: '~2m 30s · Kitchen',
            trailing: const SettingsTag('Alert sent'),
            onTap: () {},
            semanticLabel: 'Today, 9:30 AM. ~2m 30s · Kitchen. Alert sent.',
          ),
        ),
      );

      expect(find.bySemanticsLabel('Today, 9:30 AM. ~2m 30s · Kitchen. Alert sent.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('is not tappable without an onTap', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const SettingsTileRow(title: 'Read only')));

      expect(find.byType(InkWell), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });

  group('SettingsSwitchRow', () {
    testWidgets('reports its state to a screen reader as one toggle', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        wrap(
          SettingsSwitchRow(
            icon: Icons.shield_outlined,
            title: 'Caregiver mode',
            subtitle: "Watch someone else, don't send SOS",
            value: true,
            onChanged: (_) {},
          ),
        ),
      );

      expect(
        find.bySemanticsLabel("Caregiver mode. Watch someone else, don't send SOS"),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('tapping the row toggles, not just the pill', (WidgetTester tester) async {
      bool? received;
      await tester.pumpWidget(
        wrap(
          SettingsSwitchRow(
            icon: Icons.call_outlined,
            title: 'Auto-answer calls',
            value: false,
            onChanged: (bool v) => received = v,
          ),
        ),
      );

      await tester.tap(find.text('Auto-answer calls'));
      expect(received, isTrue);
    });
  });

  group('SettingsScreenHeader', () {
    testWidgets('shows the back row only for a pushed route', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const SettingsScreenHeader(title: 'Profile')));
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      await tester.pumpWidget(
        wrap(SettingsScreenHeader(title: 'Mode', backLabel: 'Profile', onBack: () {})),
      );
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('renders a trailing action beside the title', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          SettingsScreenHeader(
            title: 'Seizure log',
            trailing: TextButton(onPressed: () {}, child: const Text('Add entry')),
          ),
        ),
      );

      expect(find.text('Seizure log'), findsOneWidget);
      expect(find.text('Add entry'), findsOneWidget);
    });

    testWidgets('does not overflow when a long title meets a trailing action', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 320,
            child: SettingsScreenHeader(
              title: 'A considerably longer screen title',
              trailing: TextButton(onPressed: () {}, child: const Text('Add entry')),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
