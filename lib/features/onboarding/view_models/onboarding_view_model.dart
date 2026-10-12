import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:seizure_app/core/constants/firebase_collection_keys.dart';
import 'package:seizure_app/core/constants/privacy_notice.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/dtos/onboarding_invite_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/helpers/phone_number.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/firebase_messaging_service.dart';
import 'package:seizure_app/core/services/circle_invite_service.dart';
import 'package:seizure_app/features/contacts/widgets/invite_picker_sheet.dart';
import 'package:seizure_app/core/services/location_service.dart';
import 'package:seizure_app/core/widgets/onboarding_progress.dart';

enum OnboardingMode { preSignup, completeProfile }

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    final OnboardingMode requestedMode =
        (Get.arguments as Map?)?['mode'] as OnboardingMode? ??
        OnboardingMode.preSignup;
    if (Get.isRegistered<OnboardingViewModel>()) {
      Get.find<OnboardingViewModel>().setMode(requestedMode);
      return;
    }
    Get.put(OnboardingViewModel()..setMode(requestedMode), permanent: true);
  }
}

class OnboardingViewModel extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final contactNameController = TextEditingController();
  final contactPhoneController = TextEditingController();
  final contactRelationController = TextEditingController();

  final PageController pageController = PageController();

  final RxInt step = 0.obs;
  final RxBool hasEmergencyContactDetails = false.obs;
  final RxBool hasCompleteEmergencyContactDetails = false.obs;
  final RxBool inviteEmergencyContact = true.obs;
  final RxnString phoneNumberError = RxnString();
  final RxnString contactNameError = RxnString();
  final RxnString contactPhoneError = RxnString();

  final RxBool isLoading = false.obs;
  final RxBool notificationsGranted = false.obs;
  final RxBool locationGranted = false.obs;

  final RxBool notificationsBlocked = false.obs;
  final RxBool locationBlocked = false.obs;
  final Rx<OnboardingMode> mode = OnboardingMode.preSignup.obs;
  String? _draftContactId;
  OnboardingInviteDto? pendingInvite;

  final RxBool privacyConsentGiven = false.obs;

  static const int totalSteps = 4;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _email => FirebaseAuth.instance.currentUser?.email ?? '';

  bool get hasDraft => nameController.text.trim().isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    mode.value =
        (Get.arguments as Map?)?['mode'] as OnboardingMode? ??
        OnboardingMode.preSignup;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCurrentPermissions();
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    contactNameController.dispose();
    contactPhoneController.dispose();
    contactRelationController.dispose();
    pageController.dispose();
    super.onClose();
  }

  Future<void> _checkCurrentPermissions() async {
    try {
      final notificationPermission = await Permission.notification.status;
      notificationsBlocked.value = notificationPermission.isPermanentlyDenied;
      if (Get.isRegistered<FirebaseMessagingService>()) {
        final messaging = Get.find<FirebaseMessagingService>();
        await messaging.refreshReadiness();
        notificationsGranted.value = messaging.notificationsAuthorized;
      } else {
        notificationsGranted.value = notificationPermission.isGranted;
      }
      locationGranted.value = await LocationService.instance().hasPermission();
    } catch (e) {
      debugPrint('[OnboardingVM] Error checking permissions: $e');
    }
  }

  OnboardingStep get currentStep => switch (step.value) {
    0 => OnboardingStep.yourName,
    1 => OnboardingStep.emergencyContact,
    2 => OnboardingStep.permissions,
    _ => OnboardingStep.consent,
  };

  bool get canAdvance {
    if (step.value == 0) return nameController.text.trim().isNotEmpty;
    // The contact step is skippable. Blocking account creation on it walled
    // off anyone without a number to hand, and `commitDraft` already treats
    // the contact as optional — only the UI insisted. A partially set up
    // account that nags is better than no account.
    if (step.value == 1) return true;
    if (step.value == 3) return privacyConsentGiven.value;
    return true;
  }

  bool get isLastStep => step.value == totalSteps - 1;

  /// "Skip for now" on the contact step when nothing has been entered, so the
  /// step reads as optional rather than as a form the user is failing.
  String get nextLabel {
    if (step.value == 1 && !hasEmergencyContactDetails.value) {
      return 'Skip for now';
    }
    return 'Next';
  }

  void onEmergencyContactChanged(String _) {
    hasEmergencyContactDetails.value =
        contactNameController.text.trim().isNotEmpty ||
        contactPhoneController.text.trim().isNotEmpty;
    hasCompleteEmergencyContactDetails.value =
        contactNameController.text.trim().isNotEmpty &&
        contactPhoneController.text.trim().isNotEmpty;
  }

  String get finishLabel => mode.value == OnboardingMode.completeProfile
      ? 'Finish setup'
      : 'Create account';

  void next() {
    if (!_validateCurrentStep()) return;
    if (!canAdvance) return;
    if (step.value < totalSteps - 1) {
      step.value++;
      _animateToStep();
    }
  }

  bool _validateCurrentStep() {
    if (step.value == 0) {
      phoneNumberError.value = PhoneNumber.validationError(
        phoneController.text,
      );
      return phoneNumberError.value == null;
    }
    if (step.value == 1) {
      final String name = contactNameController.text.trim();
      final String phone = contactPhoneController.text.trim();
      if (name.isEmpty && phone.isEmpty) {
        contactNameError.value = null;
        contactPhoneError.value = null;
        return true;
      }
      contactNameError.value = name.isEmpty ? 'Name is required' : null;
      contactPhoneError.value = PhoneNumber.validationError(
        phone,
        required: true,
      );
      return contactNameError.value == null && contactPhoneError.value == null;
    }
    return true;
  }

  void back() {
    if (step.value > 0) {
      step.value--;
      _animateToStep();
    }
  }

  void _animateToStep() => pageController.animateToPage(
    step.value,
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOut,
  );

  void goToSignIn() => Get.offAllNamed(AppRoutes.login);

  void setPrivacyConsent(bool value) => privacyConsentGiven.value = value;

  Future<void> requestNotifications() async {
    try {
      if (Get.isRegistered<FirebaseMessagingService>()) {
        final messaging = Get.find<FirebaseMessagingService>();
        if (notificationsBlocked.value) {
          await messaging.openNotificationSettings();
        } else {
          await messaging.enableNotifications();
        }
        await _checkCurrentPermissions();
        return;
      }

      if (notificationsBlocked.value) {
        await AppSettings.openAppSettings(type: AppSettingsType.notification);
        await _checkCurrentPermissions();
        return;
      }
      final result = await Permission.notification.request();
      notificationsGranted.value = result.isGranted;
      notificationsBlocked.value = result.isPermanentlyDenied;
    } catch (e) {
      debugPrint('[OnboardingVM] Error requesting notification permission: $e');
    }
  }

  Future<void> requestLocation() async {
    try {
      if (locationBlocked.value) {
        await AppSettings.openAppSettings(type: AppSettingsType.location);
        return;
      }
      locationGranted.value = await LocationService.instance()
          .requestPermission();
      if (!locationGranted.value) {
        locationBlocked.value =
            await Permission.locationWhenInUse.isPermanentlyDenied;
      }
    } catch (e) {
      debugPrint('[OnboardingVM] Error requesting location permission: $e');
    }
  }

  Future<void> finish() async {
    if (mode.value == OnboardingMode.preSignup) {
      Get.toNamed(AppRoutes.signup);
      return;
    }

    isLoading.value = true;
    final bool saved = await commitDraft();
    isLoading.value = false;

    if (saved) {
      Get.offAllNamed(AppRoutes.root);
      final invite = pendingInvite;
      if (invite != null) InvitePickerSheet.showAfterNavigation(invite);
    }
  }

  Future<bool> commitDraft() async {
    final String uid = _uid;
    if (uid.isEmpty) {
      debugPrint('[OnboardingVM] commitDraft called with no signed-in user');
      return false;
    }

    if (!privacyConsentGiven.value) {
      debugPrint(
        '[OnboardingVM] commitDraft refused: no privacy consent recorded',
      );
      return false;
    }

    try {
      final FirestoreService firestore = FirestoreService.instance();
      final String phone = phoneController.text.trim();
      final String contactName = contactNameController.text.trim();
      final String contactPhone = contactPhoneController.text.trim();
      final String relation = contactRelationController.text.trim();

      final ResultDto<void> userResult = await firestore.upsertUser(
        UserDto(
          uid: uid,
          email: _email,
          displayName: nameController.text.trim(),
          phone: phone.isEmpty ? null : phone,
          privacyConsentAt: DateTime.now(),
          privacyConsentVersion: PrivacyNotice.version,
        ),
      );

      ResultDto<void> contactResult = ResultDto.success(null);
      if (contactName.isNotEmpty && contactPhone.isNotEmpty) {
        _draftContactId ??= firestore.newDocumentId(
          FirebaseCollectionKeys.contacts,
        );
        contactResult = await firestore.upsertContact(
          ContactDto(
            id: _draftContactId!,
            userId: uid,
            name: contactName,
            phone: contactPhone,
            relation: relation.isEmpty ? null : relation,
            priority: 0,
            createdAt: DateTime.now(),
          ),
        );
      }

      if (!userResult.isSuccess || !contactResult.isSuccess) {
        debugPrint(
          '[OnboardingVM] Commit failed: ${userResult.error ?? contactResult.error}',
        );
        Get.snackbar('Setup not saved', 'Check your connection and try again.');
        return false;
      }

      await AppModeService.instance().setOnboardingCompleted(true);
      pendingInvite = null;
      if (inviteEmergencyContact.value &&
          contactName.isNotEmpty &&
          contactPhone.isNotEmpty &&
          _draftContactId != null) {
        final inviteResult = await CircleInviteService.instance()
            .createCircleInvite(contactId: _draftContactId!);
        if (inviteResult.isSuccess && inviteResult.data != null) {
          pendingInvite = OnboardingInviteDto(
            contactId: _draftContactId!,
            contactName: contactName,
            phone: contactPhone,
            code: inviteResult.data!,
          );
        } else {
          Get.snackbar(
            'Invite not created',
            inviteResult.error ??
                'You can invite this contact from My Circle later.',
          );
        }
      }
      return true;
    } catch (e) {
      debugPrint('[OnboardingVM] Commit failed: $e');
      Get.snackbar('Setup not saved', 'Check your connection and try again.');
      return false;
    }
  }

  static Future<void> discardDraft() async {
    if (Get.isRegistered<OnboardingViewModel>()) {
      await Get.delete<OnboardingViewModel>(force: true);
    }
  }

  static Future<({bool saved, OnboardingInviteDto? invite})>
  commitAndDisposeDraft() async {
    if (!Get.isRegistered<OnboardingViewModel>()) {
      return (saved: true, invite: null);
    }

    final OnboardingViewModel vm = Get.find<OnboardingViewModel>();
    if (vm.hasDraft) {
      final bool saved = await vm.commitDraft();
      if (!saved) return (saved: false, invite: null);
    }

    final invite = vm.pendingInvite;
    await Get.delete<OnboardingViewModel>(force: true);
    return (saved: true, invite: invite);
  }

  void setMode(OnboardingMode value) => mode.value = value;
}
