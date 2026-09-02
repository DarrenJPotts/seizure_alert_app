import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/features/sos/widgets/sos_button_widget.dart';
import 'package:seizure_app/features/sos/widgets/sos_contacts_summary.dart';

import '../support/fixtures.dart';
import '../support/pump.dart';

void main() {
  group('SOSButton', () {
    testWidgets('fires only on release, not on press', (WidgetTester tester) async {
      // A press that slides off the control must not send an alert, so the
      // callback is wired to onTapUp rather than onTapDown.
      int fired = 0;
      await tester.pumpWidget(wrap(SOSButton(onPressed: () => fired++)));

      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('SOS')));
      await tester.pump();
      expect(fired, 0, reason: 'still held down');

      await gesture.up();
      await tester.pump();
      expect(fired, 1);
    });

    testWidgets('does not fire when the press is cancelled', (WidgetTester tester) async {
      int fired = 0;
      await tester.pumpWidget(wrap(SOSButton(onPressed: () => fired++)));

      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('SOS')));
      await tester.pump();
      await gesture.cancel();
      await tester.pump();

      expect(fired, 0);
    });

    testWidgets('is a large target', (WidgetTester tester) async {
      // Tapped by someone mid-aura with impaired coordination, so it is far
      // above the 48dp minimum on purpose.
      await tester.pumpWidget(wrap(SOSButton(onPressed: () {})));

      final Size size = tester.getSize(find.ancestor(of: find.text('SOS'), matching: find.byType(AnimatedContainer)));

      expect(size.width, greaterThanOrEqualTo(150));
      expect(size.height, greaterThanOrEqualTo(150));
    });

    testWidgets('survives repeated presses', (WidgetTester tester) async {
      int fired = 0;
      await tester.pumpWidget(wrap(SOSButton(onPressed: () => fired++)));

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('SOS'));
        await tester.pump();
      }

      expect(fired, 3);
      expect(tester.takeException(), isNull);
    });
  });

  group('CountdownAlertDialog', () {
    testWidgets('counts down and confirms once it reaches zero', (WidgetTester tester) async {
      int confirmed = 0;
      await tester.pumpWidget(wrapBounded(CountdownAlertDialog(onConfirm: () => confirmed++, onCancel: () {})));

      // Ten seconds, not five. Five was not enough for someone mid-aura with
      // impaired motor control to find and hit Cancel.
      expect(find.text('10'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('9'), findsOneWidget);

      await tester.pump(const Duration(seconds: 8));
      expect(find.text('1'), findsOneWidget);
      expect(confirmed, 0, reason: 'not yet — one second still to run');

      await tester.pump(const Duration(seconds: 1));
      expect(confirmed, 1);
    });

    testWidgets('confirms exactly once, not on every subsequent tick', (WidgetTester tester) async {
      int confirmed = 0;
      await tester.pumpWidget(wrapBounded(CountdownAlertDialog(onConfirm: () => confirmed++, onCancel: () {})));

      await tester.pump(const Duration(seconds: 15));

      expect(confirmed, 1);
    });

    testWidgets('cancelling invokes the callback and never confirms', (WidgetTester tester) async {
      int confirmed = 0;
      int cancelled = 0;
      await tester.pumpWidget(
        wrapBounded(CountdownAlertDialog(onConfirm: () => confirmed++, onCancel: () => cancelled++)),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(cancelled, 1);
      expect(confirmed, 0);
    });

    testWidgets('pluralises the countdown copy correctly', (WidgetTester tester) async {
      await tester.pumpWidget(wrapBounded(CountdownAlertDialog(onConfirm: () {}, onCancel: () {})));

      expect(find.text('Your circle is notified in 10 seconds.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 9));
      expect(
        find.text('Your circle is notified in 1 second.'),
        findsOneWidget,
        reason: 'singular at one second remaining',
      );

      // Let the timer finish so the test does not end with it pending.
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('tells the user that inaction sends the alert', (WidgetTester tester) async {
      await tester.pumpWidget(wrapBounded(CountdownAlertDialog(onConfirm: () {}, onCancel: () {})));

      expect(find.text('Do nothing and help is on the way'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
    });
  });

  group('SosContactsSummary', () {
    testWidgets('shows an empty state with no contacts', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const SosContactsSummary(contacts: <ContactDto>[])));

      expect(find.text('You have no contacts to notify yet.'), findsOneWidget);
    });

    testWidgets('uses the singular for one contact', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(SosContactsSummary(contacts: <ContactDto>[Fixtures.contact()])));

      expect(find.text('1 contact will be notified'), findsOneWidget);
    });

    testWidgets('counts push and SMS channels separately', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          SosContactsSummary(
            contacts: <ContactDto>[
              Fixtures.contact(id: 'a'),
              Fixtures.contact(id: 'b', notifyViaPush: false),
            ],
          ),
        ),
      );

      expect(find.text('2 contacts will be notified'), findsOneWidget);
      expect(find.text('1 by push · 2 by SMS · location included'), findsOneWidget);
    });

    testWidgets('collapses to three avatars plus an overflow badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(SosContactsSummary(contacts: List<ContactDto>.generate(5, (int i) => Fixtures.contact(id: 'c$i')))),
      );

      expect(find.text('5 contacts will be notified'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('shows no overflow badge at exactly three contacts', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(SosContactsSummary(contacts: List<ContactDto>.generate(3, (int i) => Fixtures.contact(id: 'c$i')))),
      );

      expect(find.textContaining('+'), findsNothing);
    });
  });
}
