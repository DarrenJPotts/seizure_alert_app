import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/features/home/view_models/home_view_model.dart';
import 'package:seizure_app/features/home/widgets/activity_grid.dart';
import 'package:seizure_app/features/home/widgets/days_free_card.dart';
import 'package:seizure_app/features/home/widgets/greeting_widget.dart';
import 'package:seizure_app/features/home/widgets/stat_chip.dart';

import '../support/pump.dart';

void main() {
  group('DaysFreeCard', () {
    testWidgets('shows an empty state when nothing has been logged', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const DaysFreeCard(days: null)));

      expect(find.text('—'), findsOneWidget);
      expect(find.text('No seizures logged yet'), findsOneWidget);
    });

    testWidgets('says Today rather than showing a zero', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const DaysFreeCard(days: 0)));

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(find.text('Last seizure was today'), findsOneWidget);
    });

    testWidgets('uses the singular for exactly one day', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const DaysFreeCard(days: 1)));

      expect(find.text('1'), findsOneWidget);
      expect(find.text('day since last seizure'), findsOneWidget);
    });

    testWidgets('uses the plural beyond one day', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const DaysFreeCard(days: 23)));

      expect(find.text('23'), findsOneWidget);
      expect(find.text('days since last seizure'), findsOneWidget);
    });

    testWidgets('renders a large day count without overflowing', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const DaysFreeCard(days: 3650)));

      expect(find.text('3650'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('StatChip', () {
    testWidgets('shows its value and label', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const StatChip(label: 'Last 7 days', value: 3)));

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Last 7 days'), findsOneWidget);
    });

    testWidgets('renders a zero rather than hiding it', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const StatChip(label: 'This month', value: 0)));

      expect(find.text('0'), findsOneWidget);
    });
  });

  group('GreetingWidget', () {
    testWidgets('shows the greeting alone when there is no name', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const GreetingWidget(greeting: 'Good morning', name: '')));

      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Good morning,'), findsNothing);
    });

    testWidgets('appends a comma and the name when there is one', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const GreetingWidget(greeting: 'Good morning', name: 'Darren')));

      expect(find.text('Good morning,'), findsOneWidget);
      expect(find.text('Darren'), findsOneWidget);
    });
  });

  group('ActivityGrid', () {
    List<GridCell> cells({Set<int> seizureAt = const <int>{}}) {
      final DateTime start = DateTime(2026, 1, 1);
      return List<GridCell>.generate(
        28,
        (int i) =>
            (date: start.add(Duration(days: i)), hasSeizure: seizureAt.contains(i), isFuture: false, isToday: i == 27),
      );
    }

    testWidgets('renders the seven weekday initials', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(ActivityGrid(cells: cells())));

      expect(find.text('M'), findsOneWidget);
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
      // Tuesday/Thursday and both weekend days share initials.
      expect(find.text('T'), findsNWidgets(2));
      expect(find.text('S'), findsNWidgets(2));
    });

    testWidgets('renders a legend for both states', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(ActivityGrid(cells: cells())));

      expect(find.text('Seizure'), findsOneWidget);
      expect(find.text('Seizure-free'), findsOneWidget);
    });

    testWidgets('lays out 28 cells regardless of content', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(ActivityGrid(cells: cells(seizureAt: <int>{3, 19}))));

      expect(find.byType(AspectRatio), findsNWidgets(28));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders a fully blank month without error', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(ActivityGrid(cells: cells())));

      expect(tester.takeException(), isNull);
    });
  });
}
