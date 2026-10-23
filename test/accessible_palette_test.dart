import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';

double contrast(Color foreground, Color background) {
  final visible = Color.alphaBlend(foreground, background).computeLuminance();
  final base = background.computeLuminance();
  return visible > base
      ? (visible + 0.05) / (base + 0.05)
      : (base + 0.05) / (visible + 0.05);
}

void main() {
  for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
    testWidgets(
      'settings secondary text meets contrast in ${theme.brightness}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: SettingsSection(
                label: 'Settings',
                children: [
                  SettingsValueRow(
                    icon: Icons.contrast,
                    label: 'Appearance',
                    value: 'System',
                  ),
                ],
              ),
            ),
          ),
        );
        final header = tester.widget<Text>(find.text('SETTINGS'));
        final value = tester.widget<Text>(find.text('System'));
        final background = theme.brightness == Brightness.dark
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surface;
        expect(
          contrast(value.style!.color!, background),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(header.style!.color!, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
        );
        expect(theme.textTheme.labelSmall!.fontSize, greaterThanOrEqualTo(12));
      },
    );
  }
}
