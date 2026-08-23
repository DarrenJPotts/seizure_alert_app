import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/location_service.dart';

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

  static const int totalSteps = 3;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _email => FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  void onInit() {
    super.onInit();
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
      notificationsGranted.value =
          (await Permission.notification.status).isGranted;
      locationGranted.value = await LocationService.instance().hasPermission();
    } catch (e) {
      debugPrint('[OnboardingVM] Error checking permissions: $e');
    }
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  bool get canAdvance {
    if (step.value == 0) return nameController.text.trim().isNotEmpty;
    if (step.value == 1) {
      return contactNameController.text.trim().isNotEmpty &&
          contactPhoneController.text.trim().isNotEmpty;
    }
    return true;
  }

  void next() {
    if (!canAdvance) return;
    if (step.value < totalSteps - 1) {
      step.value++;
      pageController.animateToPage(
        step.value,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void back() {
    if (step.value > 0) {
      step.value--;
      pageController.animateToPage(
        step.value,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

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

  // ─── Complete onboarding ────────────────────────────────────────────────────

  Future<void> complete() async {
    isLoading.value = true;

    try {
      final firestoreService = FirestoreService.instance();
      final now = DateTime.now();

      final phone = phoneController.text.trim();
      final userResult = await firestoreService.upsertUser(UserDto(
        uid: _uid,
        email: _email,
        displayName: nameController.text.trim(),
        phone: phone.isEmpty ? null : phone,
      ));

      final contactResult = await firestoreService.upsertContact(ContactDto(
        id: now.millisecondsSinceEpoch.toString(),
        userId: _uid,
        name: contactNameController.text.trim(),
        phone: contactPhoneController.text.trim(),
        relation: contactRelationController.text.trim().isEmpty
            ? null
            : contactRelationController.text.trim(),
        priority: 0,
        createdAt: now,
      ));

      if (!userResult.isSuccess || !contactResult.isSuccess) {
        debugPrint(
            '[OnboardingVM] Error completing onboarding: ${userResult.error ?? contactResult.error}');
        Get.snackbar('Setup Not Saved', 'Check your connection and try again.');
        return;
      }

      Get.offAllNamed(AppRoutes.root);
    } catch (e) {
      debugPrint('[OnboardingVM] Error completing onboarding: $e');
      Get.snackbar('Setup Not Saved', 'Check your connection and try again.');
    } finally {
      isLoading.value = false;
    }
  }
}
