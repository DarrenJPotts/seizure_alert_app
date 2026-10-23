import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';

typedef ChangePasswordCallback =
    Future<ResultDto<void>> Function({
      required String currentPassword,
      required String newPassword,
    });

class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key, required this.onChangePassword});

  final ChangePasswordCallback onChangePassword;

  static Future<void> show({
    required ChangePasswordCallback onChangePassword,
  }) => AppBottomSheet.show(
    context: Get.context!,
    builder: (_) => ChangePasswordSheet(onChangePassword: onChangePassword),
  );

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _isBusy = false;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty) {
      setState(() => _error = 'Enter your current password.');
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters.');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }
    if (newPassword == currentPassword) {
      setState(
        () => _error = 'New password must be different from the current one.',
      );
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });

    final result = await widget.onChangePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _isBusy = false;
        _done = true;
      });
    } else {
      setState(() {
        _isBusy = false;
        _error = result.error;
      });
    }
  }

  InputDecoration _passwordDeco({
    required String hint,
    required bool obscure,
    required VoidCallback onToggleObscure,
  }) {
    final InputDecorationThemeData fieldTheme = Theme.of(
      context,
    ).inputDecorationTheme;
    final bool hasError = _error != null;

    return InputDecoration(
      hintText: hint,
      enabledBorder: hasError ? fieldTheme.errorBorder : null,
      focusedBorder: hasError ? fieldTheme.focusedErrorBorder : null,
      suffixIcon: IconButton(
        onPressed: onToggleObscure,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_done) ...[
            Text(
              'Password updated',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Dimensions.twelve),
            Text(
              'Your password has been changed.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: Dimensions.twentyFour),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.ink,
                  foregroundColor: context.paper,
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.sixteen,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      context.design.cardRadius,
                    ),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
            const SizedBox(height: Dimensions.eight),
          ] else ...[
            Text(
              'Change Password',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Dimensions.twentyFour),

            Text(
              'Current password',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.secondaryInk,
              ),
            ),
            const SizedBox(height: Dimensions.eight),
            TextField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrent,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: _passwordDeco(
                hint: 'Enter your current password',
                obscure: _obscureCurrent,
                onToggleObscure: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
            const SizedBox(height: Dimensions.twentyFour),

            Text(
              'New password',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.secondaryInk,
              ),
            ),
            const SizedBox(height: Dimensions.eight),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: _passwordDeco(
                hint: 'At least 6 characters',
                obscure: _obscureNew,
                onToggleObscure: () =>
                    setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            const SizedBox(height: Dimensions.twentyFour),

            Text(
              'Confirm new password',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.secondaryInk,
              ),
            ),
            const SizedBox(height: Dimensions.eight),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureNew,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: _passwordDeco(
                hint: 'Re-enter your new password',
                obscure: _obscureNew,
                onToggleObscure: () =>
                    setState(() => _obscureNew = !_obscureNew),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: Dimensions.eight),
              Text(
                _error!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ],
            const SizedBox(height: Dimensions.twentyFour),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBusy ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.ink,
                  foregroundColor: context.paper,
                  disabledBackgroundColor: context.ink.withValues(alpha: 0.38),
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.sixteen,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      context.design.cardRadius,
                    ),
                  ),
                ),
                child: _isBusy
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: context.paper,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Update password'),
              ),
            ),
            const SizedBox(height: Dimensions.eight),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isBusy ? null : () => Get.back(),
                style: TextButton.styleFrom(foregroundColor: context.ink),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(height: Dimensions.eight),
          ],
        ],
      ),
    );
  }
}
