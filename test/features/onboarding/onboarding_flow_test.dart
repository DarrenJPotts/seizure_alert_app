import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/widgets/onboarding_progress.dart';
import 'package:seizure_app/features/onboarding/view_models/onboarding_view_model.dart';

import '../../support/pump.dart';

/// Onboarding now runs *before* sign-up, and the answers live on the view model
/// until an account exists to attach them to. Two things are worth pinning:
/// the step arithmetic behind the progress bar, and the promise that nothing
/// reaches Firestore early.
void main() {
  // The view model builds TextEditingControllers and a PageController as
  // fields, so the binding has to exist before the constructor runs.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingStep', () {
    test('counts Welcome as already done', () {
      // The whole point of moving onboarding ahead of sign-up: the first
      // screen a new user sees already has progress on the bar.
      expect(OnboardingStep.welcome.completed, 0);
      expect(OnboardingStep.yourName.completed, 1);
      expect(OnboardingStep.total, 6);
    });

    test('reaches five of six by the account screen', () {
      expect(OnboardingStep.createAccount.completed, 5);
      expect(OnboardingStep.createAccount.completed, lessThan(OnboardingStep.total));
    });

    test('runs in flow order with no gaps', () {
      expect(
        OnboardingStep.values.map((OnboardingStep s) => s.completed),
        <int>[0, 1, 2, 3, 4, 5],
      );
    });

    test('every step is labelled for the progress bar', () {
      for (final OnboardingStep step in OnboardingStep.values) {
        expect(step.label, isNotEmpty);
      }
    });
  });

  group('OnboardingViewModel', () {
    late OnboardingViewModel vm;

    setUp(() => vm = OnboardingViewModel());
    tearDown(() => vm.onClose());

    test('maps its three screens onto the five-step run', () {
      vm.step.value = 0;
      expect(vm.currentStep, OnboardingStep.yourName);
      expect(vm.currentStep.completed, 1, reason: 'Welcome already banked');

      vm.step.value = 1;
      expect(vm.currentStep, OnboardingStep.emergencyContact);

      vm.step.value = 2;
      expect(vm.currentStep, OnboardingStep.permissions);
      expect(vm.isLastStep, isFalse);

      vm.step.value = 3;
      expect(vm.currentStep, OnboardingStep.consent);
      expect(vm.isLastStep, isTrue);
    });

    test('gates the name step on a name being entered', () {
      vm.step.value = 0;
      expect(vm.canAdvance, isFalse);

      vm.nameController.text = '   ';
      expect(vm.canAdvance, isFalse, reason: 'whitespace is not a name');

      vm.nameController.text = 'Thandi';
      expect(vm.canAdvance, isTrue);
    });

    test('lets the contact step be skipped', () {
      // Requiring a contact here walled off anyone without a number to hand,
      // and since onboarding now precedes sign-up that blocked account
      // creation outright. `commitDraft` already treats it as optional.
      vm.step.value = 1;
      expect(vm.canAdvance, isTrue);
      expect(vm.nextLabel, 'Skip for now');

      vm.contactNameController.text = 'Naledi';
      expect(vm.nextLabel, 'Next', reason: 'stops offering to skip once they start');
    });

    test('lets the permissions step through either way', () {
      // Permissions can be declined. Blocking here would trap a user who said
      // no, and the app degrades without them rather than breaking.
      vm.step.value = 2;
      expect(vm.canAdvance, isTrue);
      expect(vm.notificationsGranted.value, isFalse);
    });

    test('does not advance past the last screen', () {
      vm.step.value = 3;
      vm.privacyConsentGiven.value = true;
      vm.next();
      expect(vm.step.value, 3);
    });

    test('does not go back past the first', () {
      vm.step.value = 0;
      vm.back();
      expect(vm.step.value, 0);
    });

    test('hasDraft tracks whether there is anything worth committing', () {
      expect(vm.hasDraft, isFalse);
      vm.nameController.text = 'Thandi';
      expect(vm.hasDraft, isTrue);
    });

    test('labels the final button by mode', () {
      expect(vm.mode.value, OnboardingMode.preSignup);
      expect(vm.finishLabel, 'Create account');

      vm.mode.value = OnboardingMode.completeProfile;
      expect(vm.finishLabel, 'Finish setup');
    });

    group('privacy consent', () {
      test('starts unticked — consent must be a positive act', () {
        // A pre-ticked box is not consent under POPIA s27. If this ever
        // defaults true, the lawful basis for processing health information
        // disappears.
        expect(vm.privacyConsentGiven.value, isFalse);
      });

      test('blocks the final step until it is given', () {
        vm.step.value = 3;
        expect(vm.canAdvance, isFalse);

        vm.setPrivacyConsent(true);
        expect(vm.canAdvance, isTrue);
      });

      test('can be withdrawn again before sign-up', () {
        vm.step.value = 3;
        vm.setPrivacyConsent(true);
        vm.setPrivacyConsent(false);
        expect(vm.canAdvance, isFalse);
      });

      test('is the only step with no way past it', () {
        // Permissions can be declined and the app degrades. Consent cannot,
        // because without it there is no basis to store anything at all.
        vm.step.value = 2;
        expect(vm.canAdvance, isTrue, reason: 'permissions are optional');

        vm.step.value = 3;
        expect(vm.canAdvance, isFalse, reason: 'consent is not');
      });
    });

    // Not covered here: `commitDraft`'s empty-uid guard, its refusal to write
    // without a recorded consent, and the fact that
    // nothing is written before sign-up. Both go through `FirebaseAuth.instance`
    // and `FirestoreService`, which throw without an initialised Firebase app.
    // Verifying "no Firestore write before the account exists" needs the
    // emulator — see test/README.md.
  });

  group('OnboardingProgress', () {
    testWidgets('fills one segment before the user has done anything', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          OnboardingProgress(
            completed: OnboardingStep.yourName.completed,
            total: OnboardingStep.total,
            label: OnboardingStep.yourName.label,
          ),
        ),
      );

      expect(find.text('Your name'), findsOneWidget);
      expect(find.text('1 of 6 done'), findsOneWidget);
      expect(_filledSegments(tester), 1);
    });

    testWidgets('fills five by the account screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          OnboardingProgress(
            completed: OnboardingStep.createAccount.completed,
            total: OnboardingStep.total,
            label: OnboardingStep.createAccount.label,
          ),
        ),
      );

      expect(find.text('5 of 6 done'), findsOneWidget);
      expect(_filledSegments(tester), 5);
    });

    testWidgets('exposes the step position to a screen reader', (WidgetTester tester) async {
      // The bar is purely visual; without this the progress is invisible to
      // anyone using a screen reader.
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        wrap(
          const OnboardingProgress(completed: 2, total: 6, label: 'Emergency contact'),
        ),
      );

      expect(find.bySemanticsLabel('Setup progress'), findsOneWidget);
      handle.dispose();
    });
  });
}

/// Segments painted black rather than `Colors.black12`.
int _filledSegments(WidgetTester tester) => tester
    .widgetList<AnimatedContainer>(
      find.descendant(of: find.byType(OnboardingProgress), matching: find.byType(AnimatedContainer)),
    )
    .where((AnimatedContainer c) => (c.decoration as BoxDecoration?)?.color == Colors.black)
    .length;
