// ignore_for_file: must_call_super
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seizure_app/core/constants/shared_pref_keys.dart';
import 'package:seizure_app/core/controllers/theme_controller/theme_controller.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/core/widgets/design_style_sheet.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';
import 'package:seizure_app/features/home/widgets/days_free_card.dart';
import 'package:seizure_app/features/home/widgets/greeting_widget.dart';
import 'package:seizure_app/features/home/widgets/quick_action_card_widget.dart';
import 'package:seizure_app/features/home/widgets/stat_chip.dart';
import 'package:seizure_app/features/root/root_view.dart';
import 'package:seizure_app/features/root/widgets/floating_bottom_nav_widget.dart';

class _RootFixture extends RootViewModel {
  @override
  void onInit() {}
}

Widget _app(ThemeController controller, Widget home) => Obx(
  () => MaterialApp(
    theme: AppTheme.lightFor(controller.resolvedDesign),
    darkTheme: AppTheme.darkFor(controller.resolvedDesign),
    themeMode: controller.resolvedMode,
    home: home,
  ),
);

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

  test(
    'styles persist independently of appearance and reject unknown values',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = ThemeController(prefs);
      await controller.setThemeMode(ThemeMode.dark);
      for (final style in AppDesignStyle.values) {
        await controller.setDesignStyle(style);
        expect(ThemeController(prefs).resolvedDesign, style);
        expect(controller.resolvedMode, ThemeMode.dark);
      }
      await prefs.setString(SharedPrefKeys.designStyle, 'removed-style');
      expect(ThemeController(prefs).resolvedDesign, AppDesign.defaultStyle);
    },
  );

  test(
    'normal releases ignore developer preferences and reject changes',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SharedPrefKeys.designStyle, 'editorial');
      final controller = ThemeController(prefs, designSwitcherEnabled: false);
      expect(controller.resolvedDesign, AppDesign.defaultStyle);
      await controller.setDesignStyle(AppDesignStyle.soft);
      expect(controller.resolvedDesign, AppDesign.defaultStyle);
      expect(prefs.getString(SharedPrefKeys.designStyle), 'editorial');
    },
  );

  testWidgets(
    'long press opens picker and changing style preserves route and input',
    (tester) async {
      final controller = Get.put(
        ThemeController(await SharedPreferences.getInstance()),
      );
      final input = TextEditingController(text: 'Unsaved note');
      addTearDown(input.dispose);
      await tester.pumpWidget(
        _app(
          controller,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: ListView(
                        children: [
                          TextField(controller: input),
                          const DesignVersionFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
                child: const Text('Open Profile'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Version 1.0.0 (1)'), findsOneWidget);
      await tester.longPress(
        find.byKey(const ValueKey('design-version-footer')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DesignStyleSheet), findsOneWidget);
      final originalRoute = ModalRoute.of(
        tester.element(find.byType(TextField)),
      )!;
      for (final style in AppDesignStyle.values) {
        final option = find.byKey(ValueKey('design-${style.name}'));
        await tester.ensureVisible(option);
        await tester.tap(option);
        await tester.pumpAndSettle();
        expect(controller.resolvedDesign, style);
        expect(input.text, 'Unsaved note');
        expect(
          ModalRoute.of(tester.element(find.byType(TextField))),
          same(originalRoute),
        );
        expect(
          Theme.of(
            tester.element(find.byType(TextField)),
          ).extension<AppDesign>()!.style,
          style,
        );
        expect(find.byType(DesignStyleSheet), findsOneWidget);
        expect(
          Theme.of(
            tester.element(find.byType(DesignStyleSheet)),
          ).extension<AppDesign>()!.style,
          style,
        );
      }
      await tester.ensureVisible(find.text('Dark'));
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(controller.resolvedMode, ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(DesignStyleSheet))).brightness,
        Brightness.dark,
      );
      expect(controller.resolvedDesign, AppDesignStyle.instrument);
      await tester.ensureVisible(find.text('Done'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(input.text, 'Unsaved note');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disabled switcher has no entry or sheet', (tester) async {
    final controller = Get.put(
      ThemeController(
        await SharedPreferences.getInstance(),
        designSwitcherEnabled: false,
      ),
    );
    await tester.pumpWidget(
      _app(controller, const Scaffold(body: DesignVersionFooter())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hold to change design style'), findsNothing);
    await tester.longPress(find.byKey(const ValueKey('design-version-footer')));
    await tester.pumpAndSettle();
    expect(find.byType(DesignStyleSheet), findsNothing);
    await DesignStyleSheet.show(
      tester.element(find.byType(DesignVersionFooter)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DesignStyleSheet), findsNothing);
  });

  for (final style in AppDesignStyle.values) {
    for (final dark in [false, true]) {
      testWidgets(
        '${style.name} dark=$dark fits narrow screens and large text',
        (tester) async {
          tester.view.physicalSize = const Size(280, 560);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final theme = dark
              ? AppTheme.darkFor(style)
              : AppTheme.lightFor(style);
          for (final scale in [1.0, 3.0]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Scaffold(
                    body: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const GreetingWidget(
                            greeting: 'Good morning',
                            name: 'Alexandra',
                          ),
                          const DaysFreeCard(days: 0),
                          const DaysFreeCard(days: 1200),
                          const Row(
                            children: [
                              Expanded(
                                child: StatChip(label: 'Last 7 days', value: 0),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: StatChip(label: 'This month', value: 2),
                              ),
                            ],
                          ),
                          QuickActionCard(
                            icon: Icons.book,
                            label: 'Add seizure entry',
                            onTap: () {},
                          ),
                          const SettingsGroup(
                            children: [
                              SettingsValueRow(
                                icon: Icons.contrast,
                                label: 'Appearance',
                                value: 'System',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          Get.put(AppModeService(await SharedPreferences.getInstance()));
          final root = _RootFixture();
          for (final caregiver in [false, true]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: Scaffold(
                  bottomNavigationBar: FloatingBottomNavWidget(
                    controller: root,
                    caregiver: caregiver,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.tap(find.byIcon(Icons.person_outline));
            await tester.pumpAndSettle();
            expect(root.currentIndex.value, caregiver ? 2 : 4);
            root.currentIndex.value = 0;
          }
          root.onClose();
        },
      );
    }
  }

  testWidgets('picker scrolls at large text on a short device', (tester) async {
    tester.view.physicalSize = const Size(280, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.put(ThemeController(await SharedPreferences.getInstance()));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(3)),
            child: DesignStyleSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Done'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
