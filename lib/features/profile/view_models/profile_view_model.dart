import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:seizure_app/core/controllers/firebase_auth_controller/firebase_auth_controller.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProfileViewModel(FirestoreService.instance()));
  }
}

class ProfileViewModel extends GetxController {
  ProfileViewModel(this._firestoreService);

  /// `Providers`
  final FirestoreService _firestoreService;

  /// `State`
  final Rxn<UserDto> user = Rxn<UserDto>();
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;
  final Rxn<String> errorMessage = Rxn<String>();
  final RxBool isDeleting = false.obs;

  /// `Permissions`
  final RxBool notificationsEnabled = false.obs;
  final RxBool locationEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
    checkPermissions();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ─── Profile ──────────────────────────────────────────────────────────────

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

  // ─── Permissions ──────────────────────────────────────────────────────────

  // permission_handler doesn't implement the OS-level location/notification
  // permission APIs on web (throws UnimplementedError) — the browser handles
  // those prompts itself via the underlying JS APIs instead, so there's
  // nothing meaningful for this native-style permissions card to check there.
  Future<void> checkPermissions() async {
    if (kIsWeb) return;

    final results = await Future.wait([Permission.notification.status, Permission.locationWhenInUse.status]);

    notificationsEnabled.value = results[0].isGranted;
    locationEnabled.value = results[1].isGranted || await Permission.locationAlways.isGranted;
  }

  Future<void> requestNotifications() async {
    if (kIsWeb) return;

    final status = await Permission.notification.request();

    await AppSettings.openAppSettings(type: AppSettingsType.notification);
    await checkPermissions();

    if (status.isGranted) {
      notificationsEnabled.value = true;
    } else if (status.isPermanentlyDenied) {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
      await checkPermissions();
    }
  }

  Future<void> requestLocation() async {
    if (kIsWeb) return;

    // Ask for whenInUse first — iOS requires this before always
    final whenInUse = await Permission.locationWhenInUse.request();

    if (whenInUse.isGranted) {
      // Then ask for always (needed for background alert detection)
      final always = await Permission.locationAlways.request();
      locationEnabled.value = always.isGranted || whenInUse.isGranted;
    } else {
      await AppSettings.openAppSettings(type: AppSettingsType.location);
      await checkPermissions();
    }
  }

  // ─── Email ────────────────────────────────────────────────────────────────

  Future<ResultDto<void>> changeEmail({required String newEmail, required String password}) {
    return FirebaseAuthController.instance().changeEmail(newEmail: newEmail, password: password);
  }

  // ─── Password ─────────────────────────────────────────────────────────────

  Future<ResultDto<void>> changePassword({required String currentPassword, required String newPassword}) {
    return FirebaseAuthController.instance()
        .changePassword(currentPassword: currentPassword, newPassword: newPassword);
  }

  // ─── Account deletion ─────────────────────────────────────────────────────

  Future<ResultDto<void>> deleteAccount(String password) async {
    isDeleting.value = true;
    final result = await FirebaseAuthController.instance().deleteAccount(password);
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
