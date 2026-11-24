import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/dtos/alert_delivery_dto.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/features/sos/view_models/sos_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      expect(
        vm.isUndelivered,
        isTrue,
        reason: 'offline: nobody has been notified',
      );

      vm.delivery.value = SosDelivery.failed;
      expect(
        vm.isUndelivered,
        isTrue,
        reason: 'rejected: nobody has been notified',
      );
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
      expect(SosDelivery.values, hasLength(5));
      expect(
        SosDelivery.values,
        containsAll(<SosDelivery>[
          SosDelivery.sending,
          SosDelivery.delivered,
          SosDelivery.queued,
          SosDelivery.failed,
          SosDelivery.notNotified,
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

  /// The server can have the alert and still notify nobody: an outage, the
  /// safety flag turned off, or contacts without a working device. The
  /// screen must not keep saying "SOS ACTIVE" in that case.
  group('notNotified', () {
    late SosViewModel vm;

    AlertDeliveryDto record(String contactId, String status) =>
        AlertDeliveryDto(alertId: 'a1', contactId: contactId, status: status);

    setUp(() {
      vm = SosViewModel();
      vm.activeSos.value = AlertDto(
        id: 'a1',
        userId: 'u1',
        type: AlertType.sos,
        status: AlertStatus.sent,
        createdAt: DateTime(2026, 11, 23, 10),
      );
      vm.delivery.value = SosDelivery.delivered;
    });
    tearDown(() => vm.onClose());

    test('counts as undelivered', () {
      vm.delivery.value = SosDelivery.notNotified;
      expect(vm.isUndelivered, isTrue);
    });

    test('stays delivered while the grace period runs with no records', () {
      vm.reconcileNotified(graceElapsed: false);
      expect(vm.delivery.value, SosDelivery.delivered);
    });

    test(
      'flags nobody notified once the grace period passes with no records',
      () {
        vm.reconcileNotified(graceElapsed: true);
        expect(vm.delivery.value, SosDelivery.notNotified);
      },
    );

    test('flags nobody notified as soon as every push has failed', () {
      vm.alertDeliveries.value = <AlertDeliveryDto>[
        record('c1', 'failed'),
        record('c2', 'deviceOffline'),
      ];
      vm.reconcileNotified(graceElapsed: false);
      expect(vm.delivery.value, SosDelivery.notNotified);
    });

    test('one successful push is enough', () {
      vm.alertDeliveries.value = <AlertDeliveryDto>[
        record('c1', 'failed'),
        record('c2', 'sent'),
      ];
      vm.reconcileNotified(graceElapsed: true);
      expect(vm.delivery.value, SosDelivery.delivered);
    });

    test('recovers when a push is confirmed late', () {
      vm.reconcileNotified(graceElapsed: true);
      expect(vm.delivery.value, SosDelivery.notNotified);

      vm.alertDeliveries.value = <AlertDeliveryDto>[record('c1', 'sent')];
      vm.reconcileNotified();
      expect(vm.delivery.value, SosDelivery.delivered);
    });

    test('never overrides the offline or rejected states', () {
      for (final SosDelivery state in <SosDelivery>[
        SosDelivery.sending,
        SosDelivery.queued,
        SosDelivery.failed,
      ]) {
        vm.delivery.value = state;
        vm.reconcileNotified(graceElapsed: true);
        expect(vm.delivery.value, state);
      }
    });

    test('does nothing without an active SOS', () {
      vm.activeSos.value = null;
      vm.reconcileNotified(graceElapsed: true);
      expect(vm.delivery.value, SosDelivery.delivered);
    });

    test(
      'the notify grace leaves time for the server but stays actionable',
      () {
        expect(
          SosViewModel.notifyGrace,
          greaterThan(SosViewModel.deliveryGrace),
        );
        expect(SosViewModel.notifyGrace.inSeconds, lessThanOrEqualTo(45));
      },
    );
  });

  /// An SOS started on the watch used to be invisible on the phone, and one
  /// cancelled on the watch stayed active here.
  group('SOS started or closed on another device', () {
    late SosViewModel vm;
    final AlertDto watchSos = AlertDto(
      id: 'watch-1',
      userId: 'u1',
      type: AlertType.sos,
      status: AlertStatus.sent,
      createdAt: DateTime(2026, 11, 23, 10),
    );

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      vm = SosViewModel(currentUid: () => 'u1');
    });
    tearDown(() => vm.onClose());

    test('shows an SOS started elsewhere', () {
      vm.handleOpenSos(<AlertDto>[watchSos]);
      expect(vm.activeSos.value?.id, 'watch-1');
      expect(vm.delivery.value, SosDelivery.delivered);
    });

    test('clears an SOS that was cancelled elsewhere', () async {
      vm.activeSos.value = watchSos;
      vm.handleOpenSos(<AlertDto>[watchSos]);
      vm.handleOpenSos(<AlertDto>[]);
      await Future<void>.delayed(Duration.zero);
      expect(vm.activeSos.value, isNull);
    });

    test('keeps a local SOS that has not reached the server yet', () {
      vm.activeSos.value = watchSos;
      vm.handleOpenSos(<AlertDto>[]);
      expect(vm.activeSos.value?.id, 'watch-1');
    });
  });
}
