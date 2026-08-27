import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/widgets/live_indicator.dart';

import '../support/pump.dart';

/// The surrounding MaterialApp/Scaffold contributes its own identity
/// `Transform`s, so the ring has to be located inside the widget under test
/// rather than by type alone.
final Finder _ring = find.descendant(of: find.byType(LiveIndicator), matching: find.byType(Transform));

/// [LiveIndicator] replaced the app's green monitoring dot, which means
/// motion — not colour — is now the only thing that says "live". That makes
/// the reduce-motion path a correctness concern rather than a nicety: if the
/// animation is the signal and the animation is off, the signal has to
/// survive some other way.
void main() {
  testWidgets('animates continuously by default', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const LiveIndicator()));

    final Transform first = tester.widget<Transform>(_ring);
    await tester.pump(const Duration(milliseconds: 600));
    final Transform later = tester.widget<Transform>(_ring);

    expect(later.transform, isNot(equals(first.transform)));

    // Leaves the tree with the controller still running; without a dispose
    // that stops it the test binding would report a leaked ticker.
    await tester.pumpWidget(wrap(const SizedBox.shrink()));
  });

  testWidgets('holds a static ring when the platform asks for reduced motion', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(data: const MediaQueryData(disableAnimations: true), child: wrap(const LiveIndicator())),
    );

    final Transform first = tester.widget<Transform>(_ring);
    await tester.pump(const Duration(milliseconds: 900));
    final Transform later = tester.widget<Transform>(_ring);

    // Unchanged frame to frame, and still drawn — the ring is visible at rest
    // rather than the indicator collapsing to a bare dot.
    expect(later.transform, equals(first.transform));
    expect(_ring, findsOneWidget);
  });

  testWidgets('scales the dot with the indicator size', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(data: const MediaQueryData(disableAnimations: true), child: wrap(const LiveIndicator(size: 28))),
    );

    final Size box = tester.getSize(find.byType(LiveIndicator));
    expect(box, const Size(28, 28));

    await tester.pumpWidget(wrap(const SizedBox.shrink()));
  });

  group('LiveStatusLabel', () {
    testWidgets('renders its label beside the indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: wrap(const LiveStatusLabel(label: 'Monitoring active')),
        ),
      );

      expect(find.text('Monitoring active'), findsOneWidget);
      expect(find.byType(LiveIndicator), findsOneWidget);
    });

    testWidgets('announces itself as live to a screen reader', (WidgetTester tester) async {
      // The pulsing ring conveys nothing to a screen reader, so the word
      // "Live" has to be in the semantics label or the state is invisible
      // to anyone using one.
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: wrap(const LiveStatusLabel(label: 'SOS ACTIVE')),
        ),
      );

      expect(find.bySemanticsLabel('Live. SOS ACTIVE'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('truncates a long label instead of overflowing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: wrapBounded(
            const SizedBox(width: 120, child: LiveStatusLabel(label: 'LIVE · STARTED 1:04:37 AGO, 3.2 km from you')),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
