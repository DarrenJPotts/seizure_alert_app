import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';

typedef ChangeEmailCallback =
    Future<ResultDto<void>> Function({
      required String newEmail,
      required String password,
    });

class ChangeEmailSheet extends StatefulWidget {
  const ChangeEmailSheet({
    super.key,
    required this.currentEmail,
    required this.onChangeEmail,
  });

  final String currentEmail;
  final ChangeEmailCallback onChangeEmail;

  static Future<void> show({
    required String currentEmail,
    required ChangeEmailCallback onChangeEmail,
  }) => AppBottomSheet.show(
    context: Get.context!,
    builder: (_) => ChangeEmailSheet(
      currentEmail: currentEmail,
      onChangeEmail: onChangeEmail,
    ),
  );

  @override
  State<ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<ChangeEmailSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isBusy = false;
  String? _error;
  String? _sentToEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final newEmail = _emailController.text.trim();
    final password = _passwordController.text;

    if (newEmail.isEmpty || !newEmail.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (newEmail == widget.currentEmail) {
      setState(() => _error = 'That is already your current email.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Enter your password to confirm.');
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });

    final result = await widget.onChangeEmail(
      newEmail: newEmail,
      password: password,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _isBusy = false;
        _sentToEmail = newEmail;
      });
    } else {
      setState(() {
        _isBusy = false;
        _error = result.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sentToEmail != null) ...[
            Text(
              'Check your inbox',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: Dimensions.twelve),
            Text(
              'We sent a confirmation link to $_sentToEmail. Your email stays the same until you confirm it there.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: Dimensions.twentyFour),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: Dimensions.sixteen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
            SizedBox(height: Dimensions.eight),
          ] else ...[
            // ── Title ───────────────────────────────────────────────────
            Text(
              'Change Email',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: Dimensions.twelve),
            Text(
              'Currently: ${widget.currentEmail}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black45),
            ),
            SizedBox(height: Dimensions.twentyFour),

            // ── New email field ────────────────────────────────────────
            Text(
              'New email address',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: Dimensions.eight),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black26),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
            ),
            SizedBox(height: Dimensions.twentyFour),

            // ── Password field ───────────────────────────────────────────
            Text(
              'Confirm your password',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: Dimensions.eight),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black26),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _error != null ? Colors.red : Colors.black12,
                    width: _error != null ? 1.5 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _error != null ? Colors.red : Colors.black,
                    width: 1.5,
                  ),
                ),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.black38,
                    size: 20,
                  ),
                ),
              ),
            ),

            // ── Inline error ─────────────────────────────────────────────
            if (_error != null) ...[
              SizedBox(height: Dimensions.eight),
              Text(
                _error!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ],
            SizedBox(height: Dimensions.twentyFour),

            // ── Send button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBusy ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.black38,
                  padding: EdgeInsets.symmetric(vertical: Dimensions.sixteen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isBusy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Send confirmation link'),
              ),
            ),
            SizedBox(height: Dimensions.eight),

            // ── Cancel ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isBusy ? null : () => Get.back(),
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text('Cancel'),
              ),
            ),
            SizedBox(height: Dimensions.eight),
          ],
        ],
      ),
    );
  }
}
