import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/constants/image_list.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/widgets/app_text_form_field.dart';
import 'package:seizure_app/core/widgets/buttons/app_button.dart';
import 'package:seizure_app/core/widgets/buttons/button_styles/base_button_style.dart';
import 'package:seizure_app/core/widgets/picture.dart';
import 'package:seizure_app/features/signup/view_models/signup_view_model.dart';

class SignupView extends GetView<SignupViewModel> {
  SignupView({super.key});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  spacing: Dimensions.thirtySix,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo + heading ──────────────────────────────────────
                    Column(
                      spacing: Dimensions.sixteen,
                      children: [
                        PictureWidget(imagePath: ImageList.appLogo, width: 220),
                        Text(
                          'Create your account',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),

                    // ── Fields ──────────────────────────────────────────────
                    Column(
                      spacing: Dimensions.sixteen,
                      children: [
                        AppTextFormField(
                          controller: controller.emailController,
                          labelText: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: controller.validateEmail,
                        ),
                        AppTextFormField(
                          controller: controller.passwordController,
                          labelText: 'Password',
                          obscureText: true,
                          enableObscureToggle: true,
                          textInputAction: TextInputAction.next,
                          validator: controller.validatePassword,
                        ),
                        AppTextFormField(
                          controller: controller.confirmPasswordController,
                          labelText: 'Confirm password',
                          obscureText: true,
                          enableObscureToggle: true,
                          textInputAction: TextInputAction.done,
                          validator: controller.validateConfirmPassword,
                        ),

                        // ── Error message ───────────────────────────────────
                        Obx(() {
                          final error = controller.errorMessage.value;
                          if (error == null || error.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            error,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          );
                        }),
                      ],
                    ),

                    // ── Actions ─────────────────────────────────────────────
                    Column(
                      spacing: Dimensions.sixteen,
                      children: [
                        Obx(() {
                          final isLoading = controller.screenState.value ==
                              GenericScreenStates.loading;
                          return AppButton(
                            buttonStyle:
                                BaseButtonStyle.primaryButton(context: context),
                            buttonText:
                                isLoading ? 'Creating account...' : 'Create account',
                            isLoading: isLoading,
                            onTap: isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      controller.register();
                                    }
                                  },
                          );
                        }),
                        AppButton(
                          buttonStyle: BaseButtonStyle.secondaryTextButtonStyle(
                              context: context),
                          buttonText: 'Already have an account? Sign in',
                          onTap: () => Get.offNamed(AppRoutes.login),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).paddingSymmetric(horizontal: Dimensions.twentyFour),
          ),
        ),
      ),
    );
  }
}
