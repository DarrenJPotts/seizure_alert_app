import 'package:seizure_app/core/themes/app_design.dart';
// ignore_for_file: must_call_super
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seizure_app/core/constants/shared_pref_keys.dart';
import 'package:seizure_app/core/controllers/theme_controller/theme_controller.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/core/widgets/app_version_footer.dart';

void main() {
  test(
    'soft editorial separates page and cards with legible monochrome text',
    () {
      for (final theme in [
        AppTheme.lightFor(AppDesignStyle.softEditorial),
        AppTheme.darkFor(AppDesignStyle.softEditorial),
      ]) {
        final design = theme.extension<AppDesign>()!;
        final panel = design.panelSurface(theme.colorScheme);
        expect(theme.scaffoldBackgroundColor, isNot(panel));
        double contrast(Color first, Color second) {
          final a = first.computeLuminance();
          final b = second.computeLuminance();
          return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
        }

        expect(
          contrast(theme.textTheme.bodyMedium!.color!, panel),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(theme.colorScheme.primary, theme.colorScheme.onPrimary),
          greaterThanOrEqualTo(4.5),
        );
        for (final color in [
          panel,
          theme.scaffoldBackgroundColor,
          theme.colorScheme.primary,
        ]) {
          expect(color.r, color.g);
          expect(color.g, color.b);
        }
      }
    },
  );

  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Seizure Alert',
      packageName: 'test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });
  tearDown(Get.reset);

  test('old design preferences cannot override Soft editorial', () async {
    for (final oldStyle in [
      'clinical',
      'bold',
      'swiss',
      'soft',
      'editorial',
      'instrument',
      'unknown',
    ]) {
      SharedPreferences.setMockInitialValues({
        SharedPrefKeys.designStyle: oldStyle,
        SharedPrefKeys.themeMode: 'dark',
      });
      final controller = ThemeController(await SharedPreferences.getInstance());
      expect(controller.resolvedDesign, AppDesignStyle.softEditorial);
      expect(controller.resolvedMode, ThemeMode.dark);
    }
  });
  testWidgets('version footer has no hidden design picker', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: AppVersionFooter()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Version 1.0.0 (1)'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
    expect(find.text('Hold to change design style'), findsNothing);
  });
}
