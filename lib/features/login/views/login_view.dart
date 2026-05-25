import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/constants/image_list.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/widgets/app_text_form_field.dart';
import 'package:seizure_app/core/widgets/buttons/app_button.dart';
import 'package:seizure_app/core/widgets/buttons/button_styles/base_button_style.dart';
import 'package:seizure_app/core/widgets/picture.dart';
import 'package:seizure_app/features/login/view_models/login_view_model.dart';

class LoginView extends GetView<LoginViewModel> {
  LoginView({super.key});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  spacing: Dimensions.thirtySix,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// Logo + tagline
                    Column(
                      spacing: Dimensions.sixteen,
                      children: [
                        PictureWidget(imagePath: ImageList.appLogo, width: 220),
                        Text(
                          'Instantly notify trusted contacts during a seizure',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),

                    /// Input fields
                    Column(
                      spacing: Dimensions.sixteen,
                      children: [
                        AppTextFormField(
                          controller: controller.emailController,
                          labelText: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        AppTextFormField(
                          controller: controller.passwordController,
                          labelText: 'Password',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                        ),

                        /// Error message
                        Obx(() {
                          final error = controller.errorMessage.value;
                          if (error == null || error.isEmpty) return SizedBox.shrink();
                          return Text(
                            error,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }),
                      ],
                    ),

                    /// Actions
                    Column(
                      spacing: Dimensions.sixteen,
                      children: [
                        Obx(() {
                          final isLoading = controller.screenState.value == GenericScreenStates.loading;
                          return AppButton(
                            buttonStyle: BaseButtonStyle.primaryButton(context: context),
                            buttonText: isLoading ? 'Logging in...' : 'Login',
                            onTap: isLoading
                                ? null
                                : () {
                              if (_formKey.currentState?.validate() ?? false) {
                                controller.login();
                              }
                            },
                          );
                        }),
                        AppButton(
                          buttonStyle: BaseButtonStyle.secondaryTextButtonStyle(context: context),
                          buttonText: 'Create an account',
                          onTap: () {},
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