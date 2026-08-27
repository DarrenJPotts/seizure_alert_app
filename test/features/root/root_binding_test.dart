import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:seizure_app/features/alert_history/view_models/alert_history_view_model.dart';
import 'package:seizure_app/features/caregiver/view_models/caregiver_view_model.dart';
import 'package:seizure_app/features/contacts/view_models/contacts_view_model.dart';
import 'package:seizure_app/features/home/view_models/home_view_model.dart';
import 'package:seizure_app/features/profile/view_models/profile_view_model.dart';
import 'package:seizure_app/features/root/root_view.dart';
import 'package:seizure_app/features/seizure_log/view_models/seizure_log_view_model.dart';
import 'package:seizure_app/features/sos/view_models/sos_view_model.dart';

/// Regression guard for a shell crash:
///
///   "SosViewModel" not found. You need to call "Get.put(SosViewModel())"
///
/// These registrations used to live in `RootViewModel`'s constructor, which
/// ran while the route's page builder was executing. Under
/// `SmartManagement.full`, GetX links a new dependency to whatever route it
/// considers current — during the `Get.offAllNamed` that every entry into the
/// shell uses, that is still the *outgoing* route, so the registrations were
/// disposed along with it. `RootViewModel` itself survived (the widget held a
/// direct reference) but the untouched `lazyPut` factories were gone, and the
/// first `Get.find<SosViewModel>()` inside `SosView` threw.
///
/// Moving them into a `Binding` attached to the route fixes the linkage. The
/// test asserts the binding *prepares* each dependency: `Get.isPrepared`
/// reports a registered-but-not-yet-constructed `lazyPut`, which is exactly
/// the state that went missing. Nothing is instantiated, so no Firebase
/// initialisation is needed.
void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test('registers every dependency the shell and its tabs resolve', () {
    RootBinding().dependencies();

    expect(Get.isPrepared<RootViewModel>(), isTrue, reason: 'shell view model');
    expect(Get.isPrepared<SosViewModel>(), isTrue, reason: 'the one that crashed');
    expect(Get.isPrepared<ProfileViewModel>(), isTrue);
    expect(Get.isPrepared<HomeViewModel>(), isTrue);
    expect(Get.isPrepared<SeizureLogViewModel>(), isTrue);
    expect(Get.isPrepared<ContactsViewModel>(), isTrue);
  });

  test('registers the caregiver-shell tabs too', () {
    // Caregiver mode is a per-device switch that can be flipped at any time
    // from Profile, so these must be available without a rebuild of the shell.
    RootBinding().dependencies();

    expect(Get.isPrepared<CaregiverViewModel>(), isTrue);
    expect(Get.isPrepared<AlertHistoryViewModel>(), isTrue);
  });

  group('fenix semantics the shell relies on', () {
    // These pin GetX behaviour rather than app code, deliberately.
    //
    // The second crash was "CaregiverViewModel" not found on switching modes.
    // GetX links a controller to whatever route is current when it is first
    // *resolved*, not when it is registered. Toggling the mode happens on the
    // pushed `/mode` route, which rebuilds the shell underneath — so
    // CaregiverViewModel was resolved for the first time while `/mode` was on
    // top and got linked to it. Popping back disposed the route, deleting the
    // controller, and a plain `lazyPut` drops its factory on delete. The
    // shell's next `Get.find` threw.
    //
    // RootBinding's fix is `fenix: true`. Asserting that directly would mean
    // resolving the real controllers, which needs Firebase — so instead these
    // pin the two behaviours the fix depends on, with a throwaway controller.
    // If a GetX upgrade changed either one, the fix would silently stop
    // working and these would catch it.

    test('fenix keeps the factory when the instance is deleted', () async {
      Get.lazyPut<_Throwaway>(_Throwaway.new, fenix: true);
      Get.find<_Throwaway>();

      expect(await Get.delete<_Throwaway>(force: true), isTrue);
      expect(Get.isPrepared<_Throwaway>(), isTrue);
      expect(Get.find<_Throwaway>(), isA<_Throwaway>(), reason: 'rebuilt on demand');
    });

    test('a plain lazyPut loses the factory — this was the bug', () async {
      Get.lazyPut<_Throwaway>(_Throwaway.new);
      Get.find<_Throwaway>();

      expect(await Get.delete<_Throwaway>(force: true), isTrue);
      expect(Get.isPrepared<_Throwaway>(), isFalse);
      expect(() => Get.find<_Throwaway>(), throwsA(anything));
    });
  });

  test('is idempotent, so re-entering the shell does not throw', () {
    // Sign out then back in runs the binding again over a container that may
    // still hold the previous registrations.
    RootBinding().dependencies();

    expect(RootBinding().dependencies, returnsNormally);
    expect(Get.isPrepared<SosViewModel>(), isTrue);
  });
}

class _Throwaway extends GetxController {}
