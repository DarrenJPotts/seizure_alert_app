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
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/features/contacts/view_models/contacts_view_model.dart';
import 'package:seizure_app/features/home/home_view.dart';
import 'package:seizure_app/features/home/view_models/home_view_model.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/features/root/root_view.dart';
import 'package:seizure_app/features/root/widgets/floating_bottom_nav_widget.dart';
import 'package:seizure_app/features/root/widgets/mode_badge.dart';

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

class _Contacts extends ContactsViewModel {
  _Contacts() : super(_Firestore(), _Invites(), _Drills());
  @override
  void onInit() {}
}

ContactDto _contact(ContactAlertTestStatus status) => ContactDto(
  id: 'contact',
  userId: 'user',
  name: 'Caregiver',
  phone: '',
  linkedUid: 'caregiver',
  lastTestStatus: status,
  createdAt: DateTime(2026),
);

class _Root extends RootViewModel {
  @override
  void onInit() {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(Get.reset);
  for (final dark in [false, true]) {
    testWidgets('Promotional home dark=$dark', (tester) async {
      if (!const bool.fromEnvironment('PROMOTIONAL_SCREENSHOTS')) return;
      tester.view.physicalSize = const Size(390, 866);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final shadows = debugDisableShadows;
      debugDisableShadows = false;
      try {
        await tester.runAsync(() async {
          await (FontLoader('RedHatDisplay')
                ..addFont(
                  rootBundle.load('assets/fonts/RedHatDisplay-Regular.ttf'),
                )
                ..addFont(
                  rootBundle.load('assets/fonts/RedHatDisplay-SemiBold.ttf'),
                )
                ..addFont(
                  rootBundle.load('assets/fonts/RedHatDisplay-Bold.ttf'),
                ))
              .load();
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        });
        final mode = Get.put(
          AppModeService(await SharedPreferences.getInstance()),
        );
        await mode.setHideCompletedSetup(true);
        final home = Get.put<HomeViewModel>(_Home());
        home.screenState.value = GenericScreenStates.loaded;
        final today = DateTime.now();
        home.seizureLogs.assignAll([
          for (final days in [12, 19])
            SeizureLogDto(
              id: '$days',
              userId: 'sample',
              occurredAt: today.subtract(Duration(days: days)),
            ),
        ]);
        final contacts = Get.put<ContactsViewModel>(_Contacts());
        contacts.screenState.value = GenericScreenStates.loaded;
        contacts.contacts.assignAll([_contact(ContactAlertTestStatus.sent)]);
        final messaging = Get.put(FirebaseMessagingService());
        messaging.notificationReadinessLoading.value = false;
        messaging.notificationAuthorization.value =
            AuthorizationStatus.authorized;
        messaging.fcmRegistrationReady.value = true;
        final root = _Root()..currentIndex.value = 0;
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: Scaffold(
                appBar: AppBar(
                  centerTitle: false,
                  title: ModeBadge(caregiver: false, onTap: () {}),
                  actions: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.history),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
                body: HomeView(onOpenContacts: () {}),
                bottomNavigationBar: FloatingBottomNavWidget(controller: root),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 3);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          await Directory('docs/promotional').create(recursive: true);
          await File(
            'docs/promotional/home-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(bytes.buffer.asUint8List());
          image.dispose();
        });
        root.onClose();
      } finally {
        debugDisableShadows = shadows;
      }
    });
  }
}
