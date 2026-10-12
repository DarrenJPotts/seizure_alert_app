import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:seizure_app/core/controllers/firebase_auth_controller/firebase_auth_controller.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/firebase_messaging_service.dart';
import 'package:seizure_app/core/services/home_widget_service.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ProfileViewModel(FirestoreService.instance()),
      fenix: true,
    );
  }
}

class ProfileViewModel extends GetxController {
  ProfileViewModel(this._firestoreService);

  final FirestoreService _firestoreService;

  final Rxn<UserDto> user = Rxn<UserDto>();
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;
  final Rxn<String> errorMessage = Rxn<String>();
  final RxBool isDeleting = false.obs;
  final RxBool isAddingHomeWidget = false.obs;
  final RxBool isRequestingNotifications = false.obs;
  final RxBool isRequestingLocation = false.obs;
  final RxBool isSendingEmailVerification = false.obs;

  bool get emailVerified =>
      FirebaseAuth.instance.currentUser?.emailVerified ?? false;

  String get homeWidgetActionLabel {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return 'Available';
    }
    return isAddingHomeWidget.value ? 'Adding…' : 'Add';
  }

  final RxBool notificationsEnabled = false.obs;
  final RxBool locationEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkPermissions();
    });
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> fetchProfile() async {
    if (_uid.isEmpty) {
      errorMessage.value = 'No authenticated user found.';
      screenState.value = GenericScreenStates.error;
      return;
    }

    screenState.value = GenericScreenStates.loading;
    errorMessage.value = null;

    final ResultDto<UserDto> result = await _firestoreService.getUser(_uid);

    if (result.isSuccess) {
      var fetched = result.data!;

      // verifyBeforeUpdateEmail only takes effect once the user confirms the
      // link sent to their new address, so the Firestore copy can lag behind
      // FirebaseAuth's record — reconcile it here if it's drifted.
      final authEmail = FirebaseAuth.instance.currentUser?.email;
      if (authEmail != null && authEmail != fetched.email) {
        fetched = UserDto(
          uid: fetched.uid,
          email: authEmail,
          displayName: fetched.displayName,
          photoUrl: fetched.photoUrl,
          phone: fetched.phone,
          fcmToken: fetched.fcmToken,
          bloodType: fetched.bloodType,
          seizureType: fetched.seizureType,
          medications: fetched.medications,
          emergencyNote: fetched.emergencyNote,
        );
        await _firestoreService.upsertUser(fetched);
      }

      user.value = fetched;
      screenState.value = GenericScreenStates.loaded;
    } else {
      errorMessage.value = result.error ?? 'Failed to load profile.';
      screenState.value = GenericScreenStates.error;
    }
  }

  Future<bool> updateProfile({
    required String displayName,
    String? phone,
    String? bloodType,
    String? seizureType,
    List<String>? medications,
    String? emergencyNote,
  }) async {
    final current = user.value;
    if (current == null) return false;

    String? clean(String? v) {
      final t = v?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    final updated = UserDto(
      uid: current.uid,
      email: current.email,
      displayName: clean(displayName),
      photoUrl: current.photoUrl,
      phone: clean(phone),
      fcmToken: current.fcmToken,
      bloodType: bloodType,
      seizureType: clean(seizureType),
      medications: medications,
      emergencyNote: clean(emergencyNote),
    );

    final result = await _firestoreService.upsertUser(updated);
    if (result.isSuccess) user.value = updated;
    return result.isSuccess;
  }

  // permission_handler doesn't implement the OS-level location/notification
  // permission APIs on web (throws UnimplementedError) — the browser handles
  // those prompts itself via the underlying JS APIs instead, so there's
  // nothing meaningful for this native-style permissions card to check there.
  Future<void> checkPermissions() async {
    if (kIsWeb) return;

    if (Get.isRegistered<FirebaseMessagingService>()) {
      final messaging = Get.find<FirebaseMessagingService>();
      await messaging.refreshReadiness();
      notificationsEnabled.value = messaging.notificationsAuthorized;
    } else {
      notificationsEnabled.value =
          (await Permission.notification.status).isGranted;
    }

    locationEnabled.value = await Permission.locationWhenInUse.isGranted;
  }

  Future<void> requestNotifications() async {
    if (kIsWeb || isRequestingNotifications.value) return;

    isRequestingNotifications.value = true;
    try {
      if (Get.isRegistered<FirebaseMessagingService>()) {
        final messaging = Get.find<FirebaseMessagingService>();
        await messaging.refreshReadiness();
        if (messaging.notificationAuthorization.value ==
            AuthorizationStatus.notDetermined) {
          await messaging.enableNotifications();
        } else if (!messaging.notificationsAuthorized) {
          await messaging.openNotificationSettings();
        }
        await checkPermissions();
        return;
      }

      final status = await Permission.notification.request();
      notificationsEnabled.value = status.isGranted;
      if (status.isPermanentlyDenied) {
        await AppSettings.openAppSettings(type: AppSettingsType.notification);
        await checkPermissions();
      }
    } finally {
      isRequestingNotifications.value = false;
    }
  }

  Future<void> requestLocation() async {
    if (kIsWeb || isRequestingLocation.value) return;

    isRequestingLocation.value = true;
    try {
      final whenInUse = await Permission.locationWhenInUse.request();
      locationEnabled.value = whenInUse.isGranted;
      if (!whenInUse.isGranted) {
        await AppSettings.openAppSettings(type: AppSettingsType.location);
        await checkPermissions();
      }
    } finally {
      isRequestingLocation.value = false;
    }
  }

  Future<void> addHomeWidget() async {
    if (kIsWeb || !Get.isRegistered<HomeWidgetService>()) {
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      Get.snackbar(
        'Add the widget',
        'Touch and hold the Home Screen, tap +, then choose Seizure Alert.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black,
        colorText: Colors.white,
      );
      return;
    }

    if (defaultTargetPlatform != TargetPlatform.android ||
        isAddingHomeWidget.value) {
      return;
    }

    isAddingHomeWidget.value = true;
    try {
      final supported = await Get.find<HomeWidgetService>().requestPin();
      if (!supported) {
        Get.snackbar(
          'Widget unavailable',
          'Add the widget from your launcher widget menu.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black,
          colorText: Colors.white,
        );
      }
    } catch (error) {
      Get.snackbar(
        'Widget not added',
        'Open your launcher widget menu and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black,
        colorText: Colors.white,
      );
    } finally {
      isAddingHomeWidget.value = false;
    }
  }

  Future<void> sendEmailVerification() async {
    if (isSendingEmailVerification.value) return;

    isSendingEmailVerification.value = true;
    try {
      final result = await FirebaseAuthController.instance()
          .sendEmailVerification();
      if (result.isSuccess) {
        await FirebaseAuth.instance.currentUser?.reload();
        Get.snackbar(
          emailVerified ? 'Email verified' : 'Verification sent',
          emailVerified
              ? 'Your email address is verified.'
              : 'Open the link in your email, then return to Profile.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Verification unavailable',
          result.error ?? 'Try again later.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black,
          colorText: Colors.white,
        );
      }
    } finally {
      isSendingEmailVerification.value = false;
    }
  }

  Future<ResultDto<void>> changeEmail({
    required String newEmail,
    required String password,
  }) {
    return FirebaseAuthController.instance().changeEmail(
      newEmail: newEmail,
      password: password,
    );
  }

  Future<ResultDto<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return FirebaseAuthController.instance().changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<ResultDto<void>> deleteAccount(String password) async {
    isDeleting.value = true;
    final result = await FirebaseAuthController.instance().deleteAccount(
      password,
    );
    isDeleting.value = false;
    return result;
  }

  String get notificationsLabel {
    return notificationsEnabled.value ? 'Enabled' : 'Disabled';
  }

  String get locationLabel {
    return locationEnabled.value ? 'Enabled' : 'Disabled';
  }
}
