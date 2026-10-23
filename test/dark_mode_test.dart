// ignore_for_file: must_call_super
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seizure_app/core/constants/shared_pref_keys.dart';
import 'package:seizure_app/core/controllers/theme_controller/theme_controller.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/core/widgets/appearance_sheet.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';
import 'package:seizure_app/features/home/widgets/days_free_card.dart';
import 'package:seizure_app/features/home/widgets/stat_chip.dart';
import 'package:seizure_app/features/root/root_view.dart';
import 'package:seizure_app/features/root/widgets/floating_bottom_nav_widget.dart';
import 'package:seizure_app/features/sos/widgets/sos_button_widget.dart';
import 'package:seizure_app/features/sos/widgets/sos_idle_sheet.dart';

class _RootFixture extends RootViewModel {
  @override
  void onInit() {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(Get.reset);

  test('appearance persists and restores each mode', () async {
    final prefs = await SharedPreferences.getInstance();
    final controller = ThemeController(prefs);
    for (final mode in ThemeMode.values) {
      await controller.setThemeMode(mode);
      expect(ThemeController(prefs).resolvedMode, mode);
    }
    await prefs.setString(SharedPrefKeys.themeMode, 'invalid');
    expect(ThemeController(prefs).resolvedMode, ThemeMode.system);
  });

  testWidgets('appearance changes theme without losing navigation or sheet', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final controller = Get.put(ThemeController(prefs));
    await tester.pumpWidget(
      Obx(
        () => MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: controller.resolvedMode,
          home: const Scaffold(body: AppearanceSettingsRow()),
        ),
      ),
    );
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(AppearanceSheet))).brightness,
      Brightness.dark,
    );
    expect(find.byType(AppearanceSheet), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(AppearanceSettingsRow), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system appearance follows device brightness', (tester) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final prefs = await SharedPreferences.getInstance();
    final controller = ThemeController(prefs);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: controller.resolvedMode,
        home: const Scaffold(body: Text('System appearance')),
      ),
    );
    for (final brightness in [Brightness.dark, Brightness.light]) {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('System appearance'))).brightness,
        brightness,
      );
    }
  });

  testWidgets('appearance sheet scrolls on short devices with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
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
            child: AppearanceSheet(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Done'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final width in [280.0, 390.0]) {
    for (final caregiver in [false, true]) {
      testWidgets('dark navigation fits $width width caregiver=$caregiver', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final prefs = await SharedPreferences.getInstance();
        Get.put(AppModeService(prefs));
        final root = _RootFixture()..currentIndex.value = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              bottomNavigationBar: FloatingBottomNavWidget(
                controller: root,
                caregiver: caregiver,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final profileIcon = find.byIcon(Icons.person_outline);
        final target = find
            .ancestor(of: profileIcon, matching: find.byType(GestureDetector))
            .first;
        expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
        final selectedDot = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        expect(
          (selectedDot.decoration! as BoxDecoration).color,
          Theme.of(tester.element(profileIcon)).colorScheme.onPrimary,
        );
        await tester.tap(find.byIcon(Icons.person_outline));
        await tester.pump();
        expect(root.currentIndex.value, caregiver ? 2 : 4);
        root.onClose();
      });
    }
  }

  testWidgets('dark surfaces retain contrast and compact Heads Up extent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final prefs = await SharedPreferences.getInstance();
    Get.put(AppModeService(prefs));
    final root = _RootFixture();
    final boundaryKey = GlobalKey();
    const capture = bool.fromEnvironment('CAPTURE_UI');
    if (capture) {
      await tester.runAsync(() async {
        await (FontLoader('RedHatDisplay')..addFont(
              rootBundle.load('assets/fonts/RedHatDisplay-Regular.ttf'),
            ))
            .load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
    }
    Widget host(Widget body) => MaterialApp(
      theme: AppTheme.darkTheme,
      home: RepaintBoundary(
        key: boundaryKey,
        child: Scaffold(
          body: SafeArea(child: body),
          bottomNavigationBar: FloatingBottomNavWidget(controller: root),
        ),
      ),
    );
    await tester.pumpWidget(
      host(
        ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Good evening', style: AppTheme.darkTheme.textTheme.bodySmall),
            Text('Darren', style: AppTheme.darkTheme.textTheme.headlineSmall),
            const SizedBox(height: 24),
            const DaysFreeCard(days: 12),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: StatChip(label: 'This month', value: 2)),
                SizedBox(width: 12),
                Expanded(child: StatChip(label: 'Total entries', value: 8)),
              ],
            ),
            const SizedBox(height: 24),
            const SettingsSection(
              label: 'My circle',
              children: [
                SettingsValueRow(
                  icon: Icons.people_outline,
                  label: 'Linked contacts',
                  value: '2 contacts',
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final headline = tester.widget<Text>(find.text('12'));
    expect(headline.style!.color!.computeLuminance(), greaterThan(0.9));
    expect(
      AppTheme.darkTheme.scaffoldBackgroundColor.computeLuminance(),
      lessThan(0.02),
    );
    expect(tester.takeException(), isNull);
    Future<void> snapshot(String name) async {
      if (!capture) return;
      await tester.runAsync(() async {
        final image =
            await (boundaryKey.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '.buildlog/dark-$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await snapshot('home');
    await tester.pumpWidget(
      host(
        SosIdleSheet(
          sheetMinSize: 0.1,
          sheetMaxSize: 0.55,
          sosHero: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tap to alert your circle',
                style: AppTheme.darkTheme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SOSButton(onPressed: () {}),
              const SizedBox(height: 24),
              const Text('2 contacts ready'),
            ],
          ),
          content: const SettingsValueRow(
            icon: Icons.schedule,
            label: 'Heads Up',
            value: '30 minutes',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final sheet = tester.widget<DraggableScrollableSheet>(
      find.byType(DraggableScrollableSheet),
    );
    expect(sheet.initialChildSize, 0.1);
    expect(tester.takeException(), isNull);
    await snapshot('sos');
    await tester.pumpWidget(
      host(
        const Padding(
          padding: EdgeInsets.all(24),
          child: SettingsSection(
            label: 'Settings',
            children: [
              SettingsValueRow(
                icon: Icons.contrast,
                label: 'Appearance',
                value: 'Dark',
              ),
              SettingsValueRow(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                value: 'Enabled',
              ),
              SettingsValueRow(
                icon: Icons.shield_outlined,
                label: 'Mode',
                value: 'Personal',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await snapshot('settings');
    root.onClose();
  });
}
