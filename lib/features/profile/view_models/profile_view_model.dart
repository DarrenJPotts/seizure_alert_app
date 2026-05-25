import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
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
      user.value = result.data;
      screenState.value = GenericScreenStates.loaded;
    } else {
      errorMessage.value = result.error ?? 'Failed to load profile.';
      screenState.value = GenericScreenStates.error;
    }
  }

  // ─── Permissions ──────────────────────────────────────────────────────────

  Future<void> checkPermissions() async {
    final results = await Future.wait([Permission.notification.status, Permission.locationWhenInUse.status]);

    notificationsEnabled.value = results[0].isGranted;
    locationEnabled.value = results[1].isGranted || await Permission.locationAlways.isGranted;
  }

  Future<void> requestNotifications() async {
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

  String get notificationsLabel {
    return notificationsEnabled.value ? 'Enabled' : 'Disabled';
  }

  String get locationLabel {
    return locationEnabled.value ? 'Enabled' : 'Disabled';
  }
}
