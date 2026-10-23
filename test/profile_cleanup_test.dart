// ignore_for_file: must_call_super
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seizure_app/core/controllers/theme_controller/theme_controller.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/network_status_service.dart';
import 'package:seizure_app/core/services/wearable_service.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/features/profile/view_models/profile_view_model.dart';
import 'package:seizure_app/features/profile/views/profile_view.dart';
import 'package:seizure_app/features/safety_readiness/view_models/safety_readiness_view_model.dart';
import 'package:seizure_app/features/safety_readiness/safety_readiness_view.dart';
import 'support/fixtures.dart';

class _Firestore extends Fake implements FirestoreService {}

class _Wearables extends Fake implements WearableService {}

class _Readiness extends SafetyReadinessViewModel {
  _Readiness()
    : super(_Firestore(), null, NetworkStatusService(), _Wearables());
  @override
  void onInit() {}
}

class _Profile extends ProfileViewModel {
  _Profile() : super(_Firestore());
  @override
  void onInit() {}
  @override
  bool get emailVerified => true;
}

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Seizure Alert',
      packageName: 'test',
      version: '1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });
  tearDown(Get.reset);
  testWidgets('permission refresh failure leaves readiness retryable', (
    tester,
  ) async {
    const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(code: 'unavailable');
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final vm = _Readiness();
    await vm.refreshReadiness();
    expect(vm.loading.value, isFalse);
    expect(vm.error.value, 'Readiness could not be refreshed. Try again.');
  });
  for (final dark in [false, true]) {
    for (final scale in [1.0, 3.0]) {
      testWidgets(
        'readiness opens and updates at 280dp dark=$dark scale=$scale',
        (tester) async {
          tester.view.physicalSize = const Size(280, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final vm = Get.put<SafetyReadinessViewModel>(_Readiness());
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(bottom: 48),
                ),
                child: const SafetyReadinessView(),
              ),
            ),
          );
          await tester.pump();
          await tester.scrollUntilVisible(find.text('Checking readiness'), 200);
          expect(find.text('Checking readiness'), findsOneWidget);
          expect(tester.takeException(), isNull);
          vm.loading.value = false;
          vm.networkAvailable.value = false;
          vm.error.value = 'Readiness could not be refreshed. Try again.';
          await tester.pump();
          expect(find.text('Setup needs attention'), findsOneWidget);
          expect(
            find.text('Readiness could not be refreshed. Try again.'),
            findsOneWidget,
          );
          await tester.scrollUntilVisible(
            find.text('Pair a Garmin watch'),
            180,
          );
          await tester.ensureVisible(find.text('Pair a Garmin watch'));
          await tester.pump();
          expect(
            find.text('Pair a Garmin watch').hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'Profile groups settings and removes duplicate mode and style controls',
    (tester) async {
      Get.put(ThemeController(await SharedPreferences.getInstance()));
      final vm = Get.put<ProfileViewModel>(_Profile());
      vm.user.value = Fixtures.user();
      vm.screenState.value = GenericScreenStates.loaded;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: ProfileView()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('SAFETY & REMINDERS'), 200);
      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('Mode'), findsNothing);
      await tester.scrollUntilVisible(find.text('Version 1.0 (1)'), 200);
      expect(find.text('ACCOUNT & SUPPORT'), findsOneWidget);
      expect(find.text('Hold to change design style'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
