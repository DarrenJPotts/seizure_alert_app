import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/core/themes/app_design.dart';
import 'package:seizure_app/features/home/widgets/days_free_card.dart';
import 'package:seizure_app/features/home/widgets/greeting_widget.dart';
import 'package:seizure_app/features/home/widgets/quick_action_card_widget.dart';
import 'package:seizure_app/features/home/widgets/stat_chip.dart';

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('Bold home widgets dark=$dark text=$scale', (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final days in <int?>[null, 0, 1, 128]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(Dimensions.twentyFour),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: Dimensions.twentyFour,
                      children: [
                        const GreetingWidget(
                          greeting: 'Good morning',
                          name: 'Alexandra',
                        ),
                        DaysFreeCard(days: days),
                        const StatChip(label: 'This month', value: 2),
                        QuickActionCard(
                          icon: Icons.book_outlined,
                          label: 'Add seizure entry',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  // Opt-in contact sheet of real widgets, using illustrative data only.
  for (final style in AppDesignStyle.values) {
    testWidgets('Render ${style.name} aesthetic preview', (tester) async {
      if (!const bool.fromEnvironment('BOLD_PREVIEW')) return;
      final previousShadowSetting = debugDisableShadows;
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = previousShadowSetting);
      tester.view.physicalSize = const Size(780, 650);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await (FontLoader('RedHatDisplay')
              ..addFont(
                rootBundle.load('assets/fonts/RedHatDisplay-Regular.ttf'),
              )
              ..addFont(
                rootBundle.load('assets/fonts/RedHatDisplay-SemiBold.ttf'),
              )
              ..addFont(rootBundle.load('assets/fonts/RedHatDisplay-Bold.ttf')))
            .load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                for (final theme in [
                  AppTheme.lightFor(style),
                  AppTheme.darkFor(style),
                ])
                  Expanded(
                    child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: theme,
                      home: Scaffold(
                        body: Padding(
                          padding: const EdgeInsets.all(Dimensions.twentyFour),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: Dimensions.twentyFour,
                            children: [
                              const GreetingWidget(
                                greeting: 'Good morning',
                                name: 'Alex',
                              ),
                              const DaysFreeCard(days: 12),
                              const Row(
                                spacing: Dimensions.twelve,
                                children: [
                                  Expanded(
                                    child: StatChip(
                                      label: 'Last 7 days',
                                      value: 0,
                                    ),
                                  ),
                                  Expanded(
                                    child: StatChip(
                                      label: 'This month',
                                      value: 2,
                                    ),
                                  ),
                                ],
                              ),
                              QuickActionCard(
                                icon: Icons.book_outlined,
                                label: 'Add seizure entry',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        await Directory('docs/design').create(recursive: true);
        await File(
          'docs/design/${style.name}-aesthetic-preview.png',
        ).writeAsBytes(bytes.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
