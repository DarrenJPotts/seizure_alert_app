import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/controllers/firebase_auth_controller/firebase_auth_controller.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/features/onboarding/view_models/onboarding_view_model.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LoginViewModel(FirebaseAuthController.instance()));
  }
}

class LoginViewModel extends GetxController {
  LoginViewModel(this._firebaseAuthController);

  /// `Providers`
  final FirebaseAuthController _firebaseAuthController;

  /// `Controllers`
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final Rxn<String> errorMessage = Rxn<String>();
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;

  Future<void> login() async {
    screenState.value = GenericScreenStates.loading;
    errorMessage.value = null;
    try {
      final ResultDto<User> result = await _firebaseAuthController.signIn(emailController.text, passwordController.text);

      if (result.isSuccess) {
        await OnboardingViewModel.discardDraft();

        screenState.value = GenericScreenStates.loaded;
        Get.offAllNamed(AppRoutes.root);
      } else {
        screenState.value = GenericScreenStates.error;
        errorMessage.value = result.error ?? 'Invalid username or password. Please try again.';
      }
    } catch (e) {
      screenState.value = GenericScreenStates.error;
      errorMessage.value = e.toString();
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
