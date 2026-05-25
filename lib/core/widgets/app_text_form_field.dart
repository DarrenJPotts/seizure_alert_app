import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/themes/app_colors.dart';

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.validator,
    this.isRequired = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.enableObscureToggle = false,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.fillColor,
    this.focusedBorderColor,
    this.enabledBorderColor,
    this.errorBorderColor,
    this.borderRadius = 12.0,
    this.contentPadding,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.onEditingComplete,
    this.autofocus = false,
    this.focusNode,
  });

  /// Controller
  final TextEditingController controller;

  /// Labels and hints
  final String labelText;
  final String? hintText;
  final String? helperText;

  /// Validation
  final String? Function(String?)? validator;
  final bool isRequired;

  /// Input configuration
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;

  /// Obscure text (for passwords)
  final bool obscureText;
  final bool enableObscureToggle;

  /// Enabled/Readonly
  final bool enabled;
  final bool readOnly;

  /// Prefix and Suffix
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;

  /// Styling
  final Color? fillColor;
  final Color? focusedBorderColor;
  final Color? enabledBorderColor;
  final Color? errorBorderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  /// Callbacks
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final void Function()? onTap;
  final void Function()? onEditingComplete;

  /// Auto-focus
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final RxBool isObscured = obscureText.obs;

    return Obx(
      () => TextFormField(
        controller: controller,
        validator: validator ?? (isRequired ? _defaultValidator : null),
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        maxLines: isObscured.value ? 1 : maxLines,
        minLines: minLines,
        obscureText: isObscured.value,
        enabled: enabled,
        readOnly: readOnly,
        autofocus: autofocus,
        focusNode: focusNode,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        onTap: onTap,
        onEditingComplete: onEditingComplete,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
          prefixIcon: prefixIcon,
          suffixIcon: _buildSuffixIcon(isObscured),
          prefixText: prefixText,
          suffixText: suffixText,
          filled: fillColor != null,
          fillColor: fillColor ?? Colors.grey.shade100,
          contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: enabledBorderColor ?? Get.theme.primaryColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: enabledBorderColor ?? Get.theme.primaryColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: focusedBorderColor ?? Get.theme.primaryColor, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: errorBorderColor ?? AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: errorBorderColor ?? AppColors.error, width: 2.0),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: AppColors.secondaryLight),
          ),
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon(RxBool isObscured) {
    if (enableObscureToggle) {
      return IconButton(
        icon: Icon(isObscured.value ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade600),
        onPressed: () => isObscured.value = !isObscured.value,
      );
    }
    return suffixIcon;
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '$labelText is required';
    }
    return null;
  }
}
