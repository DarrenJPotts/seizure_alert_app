import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/features/medical_card/medical_card_view.dart';
import 'package:seizure_app/features/medical_card/models/medical_card_data.dart';

UserDto sample() => UserDto(
  uid: 'private-uid',
  email: 'private@example.test',
  phone: 'private-phone',
  fcmToken: 'private-token',
  displayName: 'Alex Morgan',
  bloodType: 'O+',
  seizureType: 'Tonic-clonic',
  medications: ['Lamotrigine'],
  emergencyNote: 'Do not restrain. Time the seizure.',
);
Widget app({
  bool dark = false,
  double scale = 1,
  Future<ShareResult> Function(ShareParams)? share,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      viewPadding: const EdgeInsets.only(bottom: 48),
      padding: const EdgeInsets.only(bottom: 48),
    ),
    child: child!,
  ),
  home: MedicalCardView(user: sample(), share: share),
);
void main() {
  test('only allowlisted selected fields reach the share payload', () {
    final data = MedicalCardData(sample());
    final text = data.shareText({
      MedicalCardField.name,
      MedicalCardField.bloodType,
    });
    expect(text, contains('Alex Morgan'));
    expect(text, contains('O+'));
    for (final hidden in [
      'private',
      'Lamotrigine',
      'Tonic-clonic',
      'Do not restrain',
    ]) {
      expect(text, isNot(contains(hidden)));
    }
    expect(data.selected({}), isEmpty);
  });
  testWidgets(
    'exclusions affect both preview and sharing; cancellation does not share',
    (tester) async {
      ShareParams? sent;
      await tester.pumpWidget(
        app(
          share: (params) async {
            sent = params;
            return const ShareResult('', ShareResultStatus.success);
          },
        ),
      );
      await tester.scrollUntilVisible(find.text('Choose details'), 150);
      await tester.tap(find.text('Choose details'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Medications'));
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Emergency note'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Lamotrigine'), findsNothing);
      await tester.scrollUntilVisible(find.text('Share medical card'), 150);
      await tester.tap(find.text('Share medical card'));
      await tester.pumpAndSettle();
      expect(sent, isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(sent, isNull);
      await tester.tap(find.text('Share medical card'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Share'));
      await tester.pumpAndSettle();
      expect(sent!.text, contains('Alex Morgan'));
      expect(sent!.text, isNot(contains('Lamotrigine')));
      expect(sent!.text, isNot(contains('Do not restrain')));
      expect(sent!.files, isNull);
      expect(sent!.uri, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('share failure stays generic and allows retry', (tester) async {
    await tester.pumpWidget(
      app(
        share: (_) async {
          throw Exception('private-token');
        },
      ),
    );
    await tester.scrollUntilVisible(find.text('Share medical card'), 150);
    await tester.tap(find.text('Share medical card'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Share'));
    await tester.pumpAndSettle();
    expect(
      find.text('The medical card could not be shared. Try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('private-token'), findsNothing);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Share medical card'),
          )
          .onPressed,
      isNotNull,
    );
  });
  testWidgets('sharing explanation scrolls at largest text on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(scale: 3));
    await tester.scrollUntilVisible(
      find.text('Share medical card'),
      250,
      maxScrolls: 50,
    );
    await tester.ensureVisible(find.text('Share medical card'));
    await tester.tap(find.text('Share medical card'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
  for (final dark in [false, true]) {
    for (final scale in [1.0, 3.0]) {
      testWidgets('card and detail sheet width=280 scale=$scale dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(app(dark: dark, scale: scale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Choose details'),
          200,
          maxScrolls: 50,
        );
        await tester.ensureVisible(find.text('Choose details'));
        await tester.tap(find.text('Choose details'));
        await tester.pumpAndSettle();
        for (final field in MedicalCardField.values) {
          final checkbox = find.widgetWithText(CheckboxListTile, field.label);
          await tester.ensureVisible(checkbox);
          await tester.tap(checkbox);
          await tester.pump();
        }
        await tester.ensureVisible(find.text('Done'));
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Share medical card'), 200);
        final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Share medical card'),
        );
        expect(button.onPressed, isNull);
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('render medical card preview dark=$dark', (tester) async {
      if (!const bool.fromEnvironment('MEDICAL_CARD_PREVIEW')) return;
      tester.view.physicalSize = const Size(430, 932);
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
      final old = debugDisableShadows;
      debugDisableShadows = false;
      try {
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: app(dark: dark),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 3);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('docs/design').create(recursive: true);
          await File(
            'docs/design/medical-card-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      } finally {
        debugDisableShadows = old;
      }
    });
  }
}
