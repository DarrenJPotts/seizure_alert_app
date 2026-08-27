import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/features/home/view_models/home_view_model.dart';

import '../../support/fixtures.dart';

/// The dashboard statistics.
///
/// These are pure functions of `seizureLogs`, so the view model is constructed
/// directly rather than through Get — that skips `onInit`, which would reach
/// for `FirebaseAuth.instance` and need a live Firebase app. Setting the
/// observable by hand exercises exactly the same code the UI reads.
void main() {
  late HomeViewModel vm;

  setUp(() {
    vm = HomeViewModel(FirestoreService(FakeFirebaseFirestore()));
  });

  /// A log placed a whole number of days before today, at midday so that
  /// nothing lands near a day boundary and makes the test time-of-day
  /// dependent.
  SeizureLogDto logDaysAgo(int days, {String id = 'log'}) {
    final DateTime now = DateTime.now();
    final DateTime day = DateTime(now.year, now.month, now.day, 12).subtract(Duration(days: days));
    return Fixtures.seizureLog(id: '$id-$days', occurredAt: day);
  }

  group('daysSinceLastSeizure', () {
    test('is null when nothing has ever been logged', () {
      expect(vm.daysSinceLastSeizure, isNull);
    });

    test('is zero on the day of the most recent seizure', () {
      vm.seizureLogs.value = <SeizureLogDto>[logDaysAgo(0)];

      expect(vm.daysSinceLastSeizure, 0);
    });

    test('counts whole days since the most recent seizure', () {
      vm.seizureLogs.value = <SeizureLogDto>[logDaysAgo(23)];

      expect(vm.daysSinceLastSeizure, 23);
    });

    test('reads the first log, which the stream orders newest first', () {
      // watchSeizureLogs orders by occurredAt descending, so index 0 is the
      // most recent. If that ordering ever changes this getter silently starts
      // reporting the oldest seizure instead.
      vm.seizureLogs.value = <SeizureLogDto>[logDaysAgo(3), logDaysAgo(90)];

      expect(vm.daysSinceLastSeizure, 3);
    });
  });

  group('last7DaysCount', () {
    test('is zero with no logs', () {
      expect(vm.last7DaysCount, 0);
    });

    test('counts only logs inside the window', () {
      vm.seizureLogs.value = <SeizureLogDto>[
        logDaysAgo(0),
        logDaysAgo(3),
        logDaysAgo(6),
        logDaysAgo(30),
        logDaysAgo(200),
      ];

      expect(vm.last7DaysCount, 3);
    });

    test('excludes a seizure well outside the window', () {
      vm.seizureLogs.value = <SeizureLogDto>[logDaysAgo(14)];

      expect(vm.last7DaysCount, 0);
    });

    test('counts multiple seizures on the same day separately', () {
      // A count of events, not of days — two seizures today is two.
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day, 9);
      vm.seizureLogs.value = <SeizureLogDto>[
        Fixtures.seizureLog(id: 'a', occurredAt: today),
        Fixtures.seizureLog(id: 'b', occurredAt: today.add(const Duration(hours: 2))),
      ];

      expect(vm.last7DaysCount, 2);
    });
  });

  group('thisMonthCount', () {
    test('is zero with no logs', () {
      expect(vm.thisMonthCount, 0);
    });

    test('counts from the first of the current month, not a rolling window', () {
      final DateTime now = DateTime.now();
      final DateTime firstOfMonth = DateTime(now.year, now.month, 1, 12);
      final DateTime lastMonth = DateTime(now.year, now.month, 1, 12).subtract(const Duration(days: 1));

      vm.seizureLogs.value = <SeizureLogDto>[
        Fixtures.seizureLog(id: 'this', occurredAt: firstOfMonth),
        Fixtures.seizureLog(id: 'prev', occurredAt: lastMonth),
      ];

      expect(vm.thisMonthCount, 1, reason: 'the last day of the previous month is excluded');
    });
  });

  group('gridData', () {
    test('always produces exactly 28 cells', () {
      expect(vm.gridData, hasLength(28));
    });

    test('marks exactly one cell as today', () {
      expect(vm.gridData.where((GridCell c) => c.isToday), hasLength(1));
    });

    test('runs oldest to newest', () {
      final List<GridCell> cells = vm.gridData;

      for (int i = 1; i < cells.length; i++) {
        expect(cells[i].date.isAfter(cells[i - 1].date), isTrue);
      }
    });

    test('marks the day a seizure occurred', () {
      vm.seizureLogs.value = <SeizureLogDto>[logDaysAgo(5)];
      final List<GridCell> cells = vm.gridData;
      final GridCell target = cells.firstWhere((GridCell c) {
        final DateTime now = DateTime.now();
        final DateTime fiveDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 5));
        return c.date == fiveDaysAgo;
      });

      expect(target.hasSeizure, isTrue);
      expect(cells.where((GridCell c) => c.hasSeizure), hasLength(1));
    });

    test('leaves every cell clear when nothing is logged', () {
      expect(vm.gridData.any((GridCell c) => c.hasSeizure), isFalse);
    });

    test('never marks a future cell as having a seizure', () {
      vm.seizureLogs.value = <SeizureLogDto>[
        Fixtures.seizureLog(id: 'future', occurredAt: DateTime.now().add(const Duration(days: 3))),
      ];

      expect(vm.gridData.where((GridCell c) => c.isFuture && c.hasSeizure), isEmpty);
    });

    test('ignores a seizure older than the 28-day window', () {
      vm.seizureLogs.value = <SeizureLogDto>[logDaysAgo(60)];

      expect(vm.gridData.any((GridCell c) => c.hasSeizure), isFalse);
    });
  });

  group('greeting', () {
    test('is one of the three time-of-day greetings', () {
      expect(vm.greeting, anyOf('Good morning', 'Good afternoon', 'Good evening'));
    });
  });

  group('firstName', () {
    // The no-user branch falls through to FirebaseAuth.instance, which needs a
    // live Firebase app, so it is not covered here. Everything below exercises
    // the loaded-user path the dashboard actually renders.

    test('takes the first word of the display name', () {
      vm.user.value = Fixtures.user();

      expect(vm.firstName, 'Darren');
    });

    test('is empty when the display name is missing or blank', () {
      vm.user.value = Fixtures.user().copyWith(displayName: '   ');

      expect(vm.firstName, isEmpty);
    });

    test('trims surrounding whitespace before splitting', () {
      vm.user.value = Fixtures.user().copyWith(displayName: '  Darren Potts  ');

      expect(vm.firstName, 'Darren');
    });

    test('returns a single-word name unchanged', () {
      vm.user.value = Fixtures.user().copyWith(displayName: 'Darren');

      expect(vm.firstName, 'Darren');
    });
  });
}
