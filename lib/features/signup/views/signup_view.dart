import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/widgets/app_text_form_field.dart';
import 'package:seizure_app/core/widgets/buttons/app_button.dart';
import 'package:seizure_app/core/widgets/buttons/button_styles/base_button_style.dart';
import 'package:seizure_app/core/widgets/onboarding_progress.dart';
import 'package:seizure_app/core/widgets/app_wordmark.dart';
import 'package:seizure_app/features/signup/view_models/signup_view_model.dart';

class SignupView extends GetView<SignupViewModel> {
  SignupView({super.key});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (controller.showSetupProgress)
              OnboardingProgress(
                completed: OnboardingStep.createAccount.completed,
                total: OnboardingStep.total,
                label: OnboardingStep.createAccount.label,
              ),
            Expanded(
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
                          Column(
                            spacing: Dimensions.sixteen,
                            children: [
                              const AppWordmark(),
                              Text(
                                'Create your account',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),

                          Obx(
                            () => Column(
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
                                  controller:
                                      controller.confirmPasswordController,
                                  labelText: 'Confirm password',
                                  obscureText: true,
                                  enableObscureToggle: true,
                                  textInputAction: TextInputAction.done,
                                  validator: controller.validateConfirmPassword,
                                ),

                                if (controller.errorMessage.value
                                    case final String error
                                    when error.isNotEmpty)
                                  Text(
                                    error,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                  ),
                              ],
                            ),
                          ),

                          Column(
                            spacing: Dimensions.sixteen,
                            children: [
                              Obx(() {
                                final isLoading =
                                    controller.screenState.value ==
                                    GenericScreenStates.loading;
                                return AppButton(
                                  buttonStyle: BaseButtonStyle.primaryButton(
                                    context: context,
                                  ),
                                  buttonText: isLoading
                                      ? 'Creating account...'
                                      : 'Create account',
                                  isLoading: isLoading,
                                  onTap: isLoading
                                      ? null
                                      : () {
                                          if (_formKey.currentState
                                                  ?.validate() ??
                                              false) {
                                            controller.register();
                                          }
                                        },
                                );
                              }),
                              AppButton(
                                buttonStyle:
                                    BaseButtonStyle.secondaryTextButtonStyle(
                                      context: context,
                                    ),
                                buttonText: 'Already have an account? Sign in',
                                onTap: () => Get.offNamed(
                                  AppRoutes.login,
                                  arguments: Get.arguments,
                                ),
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
          ],
        ),
      ),
    );
  }
}
