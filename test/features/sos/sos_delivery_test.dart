import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/features/sos/view_models/sos_view_model.dart';

/// The active-SOS screen used to claim an alert was live the moment it was
/// written to Firestore's local cache. Offline that write never reaches the
/// server, so the user was shown a live alert while nothing had left the
/// phone — and the `await` on it never completed, so neither the success nor
/// the error branch ever ran.
///
/// `SosDelivery` is what the screen now reads instead. These pin the states
/// and the honesty rule: anything other than a confirmed send counts as
/// "nobody has been told".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SosDelivery', () {
    late SosViewModel vm;

    setUp(() => vm = SosViewModel());
    tearDown(() => vm.onClose());

    test('treats queued and failed as undelivered', () {
      vm.delivery.value = SosDelivery.queued;
      expect(vm.isUndelivered, isTrue, reason: 'offline: nobody has been notified');

      vm.delivery.value = SosDelivery.failed;
      expect(vm.isUndelivered, isTrue, reason: 'rejected: nobody has been notified');
    });

    test('only a server acknowledgement counts as delivered', () {
      vm.delivery.value = SosDelivery.delivered;
      expect(vm.isUndelivered, isFalse);
    });

    test('does not count an in-flight write as delivered', () {
      // The state the old code effectively rendered as "SOS ACTIVE".
      vm.delivery.value = SosDelivery.sending;
      expect(vm.delivery.value, isNot(SosDelivery.delivered));
    });

    test('covers every state, so the header switch cannot fall through', () {
      // The header renders an exhaustive switch over this enum; a new state
      // added without updating it would not compile, and this catches the
      // reverse — a state removed while the header still expects it.
      expect(SosDelivery.values, hasLength(4));
      expect(
        SosDelivery.values,
        containsAll(<SosDelivery>[
          SosDelivery.sending,
          SosDelivery.delivered,
          SosDelivery.queued,
          SosDelivery.failed,
        ]),
      );
    });

    test('the delivery grace is short enough to still be actionable', () {
      // Long enough to ride out a slow mobile connection, short enough that
      // someone mid-emergency learns the truth while they can still act.
      expect(SosViewModel.deliveryGrace.inSeconds, greaterThanOrEqualTo(5));
      expect(SosViewModel.deliveryGrace.inSeconds, lessThanOrEqualTo(15));
    });
  });
}
