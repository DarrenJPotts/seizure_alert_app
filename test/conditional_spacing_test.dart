// ignore_for_file: must_call_super
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/alert_drill_service.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/core/services/circle_invite_service.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/firebase_messaging_service.dart';
import 'package:seizure_app/core/themes/app_design.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/features/contacts/view_models/contacts_view_model.dart';
import 'package:seizure_app/features/home/home_view.dart';
import 'package:seizure_app/features/home/view_models/home_view_model.dart';
import 'package:seizure_app/features/home/widgets/upcoming_reminder_card.dart';
import 'package:seizure_app/features/reminders/view_models/reminders_view_model.dart';
import 'package:seizure_app/features/home/widgets/greeting_widget.dart';
import 'package:seizure_app/features/home/widgets/completed_setup_dismissible.dart';

class _Firestore extends Fake implements FirestoreService {}

class _Invites extends Fake implements CircleInviteService {}

class _Drills extends Fake implements AlertDrillService {}

class _Home extends HomeViewModel {
  _Home() : super(_Firestore());
  @override
  void onInit() {}
  @override
  String get firstName => user.value?.displayName ?? 'Alex';
}

class _Reminders extends RemindersViewModel {
  _Reminders() : super(_Firestore(), null);
  @override
  void onInit() {}
}

class _Contacts extends ContactsViewModel {
  _Contacts() : super(_Firestore(), _Invites(), _Drills());
  @override
  void onInit() {}
}

ContactDto _contact(ContactAlertTestStatus status) => ContactDto(
  id: 'contact',
  userId: 'user',
  name: 'Caregiver',
  phone: '+27821234567',
  linkedUid: 'caregiver',
  lastTestStatus: status,
  createdAt: DateTime(2026),
);

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(Get.reset);

  for (final style in AppDesignStyle.values) {
    for (final initiallyHidden in [false, true]) {
      testWidgets(
        '${style.name}: hidden setup leaves one gap, restored setup has normal gaps (saved=$initiallyHidden)',
        (tester) async {
          tester.view.physicalSize = const Size(390, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final prefs = await SharedPreferences.getInstance();
          final mode = Get.put(AppModeService(prefs));
          await mode.setHideCompletedSetup(initiallyHidden);
          Get.put<RemindersViewModel>(_Reminders()).loading.value = false;
          final home = Get.put<HomeViewModel>(_Home());
          home.screenState.value = GenericScreenStates.loaded;
          final contacts = Get.put<ContactsViewModel>(_Contacts());
          contacts.screenState.value = GenericScreenStates.loaded;
          contacts.contacts.assignAll([_contact(ContactAlertTestStatus.sent)]);
          final messaging = Get.put(FirebaseMessagingService());
          messaging.notificationReadinessLoading.value = false;
          messaging.notificationAuthorization.value =
              AuthorizationStatus.authorized;
          messaging.fcmRegistrationReady.value = true;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightFor(style),
              home: Scaffold(body: HomeView(onOpenContacts: () {})),
            ),
          );
          await tester.pumpAndSettle();
          final gap = AppDesign(style).sectionGap;
          final greeting = find.byType(GreetingWidget);
          final summary = find
              .descendant(
                of: find.byType(UpcomingReminderCard),
                matching: find.byType(Material),
              )
              .first;
          final setup = find.byType(CompletedSetupDismissible);
          if (!initiallyHidden) {
            expect(
              tester.getTopLeft(setup).dy - tester.getBottomLeft(greeting).dy,
              closeTo(gap, 0.01),
            );
            expect(
              tester.getTopLeft(summary).dy - tester.getBottomLeft(setup).dy,
              closeTo(gap, 0.01),
            );
            await tester.drag(find.byType(Dismissible), const Offset(-800, 0));
            await tester.pumpAndSettle();
          }
          expect(find.text('Setup check'), findsNothing);
          expect(
            tester.getTopLeft(summary).dy - tester.getBottomLeft(greeting).dy,
            closeTo(gap, 0.01),
          );
          expect(mode.hideCompletedSetup.value, isTrue);

          // A readiness problem must return with both normal section gaps.
          contacts.contacts.assignAll([
            _contact(ContactAlertTestStatus.failed),
          ]);
          await tester.pumpAndSettle();
          expect(find.text('Setup check'), findsOneWidget);
          expect(
            tester.getTopLeft(setup).dy - tester.getBottomLeft(greeting).dy,
            closeTo(gap, 0.01),
          );
          expect(
            tester.getTopLeft(summary).dy - tester.getBottomLeft(setup).dy,
            closeTo(gap, 0.01),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
