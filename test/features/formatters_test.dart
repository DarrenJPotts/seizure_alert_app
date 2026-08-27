import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/features/heads_up/view_models/heads_up_view_model.dart';
import 'package:seizure_app/features/sos/view_models/sos_view_model.dart';

/// The duration and distance strings shown during a live alert.
///
/// Small functions, but they are read under stress — by someone mid-aura, or by
/// a caregiver deciding whether to drive over. An off-by-one or a lost zero is
/// worth catching.
void main() {
  // HeadsUpViewModel builds a TextEditingController as a field, which needs the
  // binding up before the constructor runs.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SosViewModel.formattedElapsed', () {
    late SosViewModel vm;

    setUp(() => vm = SosViewModel());
    tearDown(() => vm.onClose());

    String format(Duration d) {
      vm.elapsed.value = d;
      return vm.formattedElapsed();
    }

    test('shows seconds only under a minute', () {
      expect(format(Duration.zero), '0s');
      expect(format(const Duration(seconds: 1)), '1s');
      expect(format(const Duration(seconds: 59)), '59s');
    });

    test('drops the seconds when they are exactly zero', () {
      expect(format(const Duration(minutes: 1)), '1m');
      expect(format(const Duration(minutes: 12)), '12m');
    });

    test('shows both parts otherwise', () {
      expect(format(const Duration(minutes: 1, seconds: 5)), '1m 5s');
      expect(format(const Duration(minutes: 12, seconds: 34)), '12m 34s');
    });

    test('keeps counting in minutes past an hour', () {
      // An SOS that has run for over an hour is the case that matters most and
      // must not silently wrap.
      expect(format(const Duration(hours: 1, minutes: 5)), '65m');
      expect(format(const Duration(hours: 2, seconds: 30)), '120m 30s');
    });
  });

  group('HeadsUpViewModel.formattedRemaining', () {
    late HeadsUpViewModel vm;

    setUp(() => vm = HeadsUpViewModel());
    tearDown(() => vm.onClose());

    String format(Duration d) {
      vm.remaining.value = d;
      return vm.formattedRemaining();
    }

    test('pads minutes and seconds to two digits under an hour', () {
      expect(format(Duration.zero), '00:00');
      expect(format(const Duration(seconds: 5)), '00:05');
      expect(format(const Duration(minutes: 9, seconds: 5)), '09:05');
      expect(format(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('adds an hours segment once there is one', () {
      expect(format(const Duration(hours: 1)), '1:00:00');
      expect(format(const Duration(hours: 1, minutes: 5, seconds: 9)), '1:05:09');
    });

    test('formats the three window lengths the user can pick', () {
      expect(format(const Duration(minutes: 30)), '30:00');
      expect(format(const Duration(minutes: 60)), '1:00:00');
      expect(format(const Duration(minutes: 120)), '2:00:00');
    });

    test('offers exactly the three documented window options', () {
      expect(HeadsUpViewModel.windowOptions, <int>[30, 60, 120]);
    });

    test('defaults to the 60 minute window', () {
      expect(vm.selectedMinutes.value, 60);
    });
  });
}
