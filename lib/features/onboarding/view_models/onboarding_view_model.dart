import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:seizure_app/core/constants/firebase_collection_keys.dart';
import 'package:seizure_app/core/constants/privacy_notice.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/location_service.dart';
import 'package:seizure_app/core/widgets/onboarding_progress.dart';

enum OnboardingMode {
  preSignup,

  completeProfile,
}

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<OnboardingViewModel>()) return;
    Get.put(OnboardingViewModel(), permanent: true);
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

  final RxBool isLoading = false.obs;
  final RxBool notificationsGranted = false.obs;
  final RxBool locationGranted = false.obs;
  final Rx<OnboardingMode> mode = OnboardingMode.preSignup.obs;

  final RxBool privacyConsentGiven = false.obs;

  static const int totalSteps = 4;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _email => FirebaseAuth.instance.currentUser?.email ?? '';

  bool get hasDraft => nameController.text.trim().isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    mode.value = (Get.arguments as Map?)?['mode'] as OnboardingMode? ?? OnboardingMode.preSignup;
    _checkCurrentPermissions();
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
      notificationsGranted.value = (await Permission.notification.status).isGranted;
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

  // ─── Navigation ────────────────────────────────────────────────────────────

  bool get canAdvance {
    if (step.value == 0) return nameController.text.trim().isNotEmpty;
    if (step.value == 1) {
      return contactNameController.text.trim().isNotEmpty && contactPhoneController.text.trim().isNotEmpty;
    }
    if (step.value == 3) return privacyConsentGiven.value;
    return true;
  }

  bool get isLastStep => step.value == totalSteps - 1;

  String get finishLabel => mode.value == OnboardingMode.completeProfile ? 'Finish setup' : 'Create account';

  void next() {
    if (!canAdvance) return;
    if (step.value < totalSteps - 1) {
      step.value++;
      _animateToStep();
    }
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

  // ─── Permissions ───────────────────────────────────────────────────────────

  Future<void> requestNotifications() async {
    try {
      final result = await Permission.notification.request();
      notificationsGranted.value = result.isGranted;
    } catch (e) {
      debugPrint('[OnboardingVM] Error requesting notification permission: $e');
    }
  }

  Future<void> requestLocation() async {
    try {
      locationGranted.value = await LocationService.instance().requestPermission();
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

    if (saved) Get.offAllNamed(AppRoutes.root);
  }

  Future<bool> commitDraft() async {
    final String uid = _uid;
    if (uid.isEmpty) {
      debugPrint('[OnboardingVM] commitDraft called with no signed-in user');
      return false;
    }

    if (!privacyConsentGiven.value) {
      debugPrint('[OnboardingVM] commitDraft refused: no privacy consent recorded');
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
        contactResult = await firestore.upsertContact(
          ContactDto(
            id: FirebaseFirestore.instance.collection(FirebaseCollectionKeys.contacts).doc().id,
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
        debugPrint('[OnboardingVM] Commit failed: ${userResult.error ?? contactResult.error}');
        Get.snackbar('Setup not saved', 'Check your connection and try again.');
        return false;
      }

      await AppModeService.instance().setOnboardingCompleted(true);
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

  static Future<void> commitAndDisposeDraft() async {
    if (!Get.isRegistered<OnboardingViewModel>()) return;

    final OnboardingViewModel vm = Get.find<OnboardingViewModel>();
    if (vm.hasDraft) {
      final bool saved = await vm.commitDraft();
      if (!saved) return;
    }

    await Get.delete<OnboardingViewModel>(force: true);
  }
}
