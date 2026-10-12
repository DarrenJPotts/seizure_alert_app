import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/controllers/firebase_auth_controller/firebase_auth_controller.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/features/onboarding/view_models/onboarding_view_model.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LoginViewModel(FirebaseAuthController.instance()));
  }
}

class LoginViewModel extends GetxController {
  LoginViewModel(this._firebaseAuthController);

  final FirebaseAuthController _firebaseAuthController;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final Rxn<String> errorMessage = Rxn<String>();
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;

  Future<void> login() async {
    screenState.value = GenericScreenStates.loading;
    errorMessage.value = null;
    try {
      final ResultDto<User> result = await _firebaseAuthController.signIn(
        emailController.text,
        passwordController.text,
      );

      if (result.isSuccess) {
        // Signing in successfully means the account already exists, so this
        // person has been through onboarding — just not on this device. The
        // completion flag lives in SharedPreferences, which a new phone starts
        // empty, so without this the splash screen keeps routing returning
        // users to onboarding instead of login every time they sign out.
        await AppModeService.instance().setOnboardingCompleted(true);
        await OnboardingViewModel.discardDraft();

        screenState.value = GenericScreenStates.loaded;
        final String? redirectRoute = _safeRedirectRoute;
        Get.offAllNamed(redirectRoute ?? AppRoutes.root);
      } else {
        screenState.value = GenericScreenStates.error;
        errorMessage.value =
            result.error ?? 'Invalid username or password. Please try again.';
      }
    } catch (_) {
      screenState.value = GenericScreenStates.error;
      errorMessage.value =
          'Unable to sign in. Check your connection and try again.';
    }
  }

  String? get _safeRedirectRoute {
    final args = Get.arguments;
    if (args is! Map) return null;

    final String? route = args[AppRoutes.redirectArgument] as String?;
    if (route == null) return null;

    if (route == AppRoutes.alertHistory ||
        route == AppRoutes.mode ||
        route.startsWith('${AppRoutes.incomingAlert}?alertId=') ||
        route.startsWith('${AppRoutes.responding}?alertId=')) {
      return route;
    }
    return null;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
