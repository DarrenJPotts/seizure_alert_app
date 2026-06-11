import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/controllers/firebase_auth_controller/firebase_auth_controller.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/routes/app_routes.dart';

class SignupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SignupViewModel(FirebaseAuthController.instance()));
  }
}

class SignupViewModel extends GetxController {
  SignupViewModel(this._authController);

  final FirebaseAuthController _authController;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final Rxn<String> errorMessage = Rxn<String>();
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!GetUtils.isEmail(value.trim())) return 'Enter a valid email address';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> register() async {
    screenState.value = GenericScreenStates.loading;
    errorMessage.value = null;

    try {
      await _authController.registerUser(
        emailController.text.trim(),
        passwordController.text,
      );
      screenState.value = GenericScreenStates.loaded;
      // Root will detect no Firestore profile and redirect to onboarding
      Get.offAllNamed(AppRoutes.root);
    } on FirebaseAuthException catch (e) {
      screenState.value = GenericScreenStates.error;
      errorMessage.value = _mapError(e.code);
    } catch (e) {
      screenState.value = GenericScreenStates.error;
      errorMessage.value = 'Something went wrong. Please try again.';
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'invalid-email':
        return 'Enter a valid email address';
      case 'weak-password':
        return 'Password is too weak — use at least 8 characters';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
