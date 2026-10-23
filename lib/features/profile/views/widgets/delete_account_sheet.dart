import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';

typedef DeleteAccountCallback =
    Future<ResultDto<void>> Function(String password);

class DeleteAccountSheet extends StatefulWidget {
  const DeleteAccountSheet({super.key, required this.onDelete});

  final DeleteAccountCallback onDelete;

  static Future<void> show({required DeleteAccountCallback onDelete}) =>
      AppBottomSheet.show(
        context: Get.context!,
        builder: (_) => DeleteAccountSheet(onDelete: onDelete),
      );

  @override
  State<DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<DeleteAccountSheet> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isBusy = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = 'Enter your password to confirm.');
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });

    final result = await widget.onDelete(password);

    if (!mounted) return;

    if (!result.isSuccess) {
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
          Text(
            'Delete Account',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Dimensions.twelve),

          Container(
            padding: const EdgeInsets.all(Dimensions.sixteen),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(context.design.cardRadius),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Text(
              'This will permanently delete your account, medical profile, seizure log, contacts, and all alert history. This cannot be undone.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
            ),
          ),
          const SizedBox(height: Dimensions.twentyFour),

          Text(
            'Confirm your password',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.secondaryInk,
            ),
          ),
          const SizedBox(height: Dimensions.eight),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              hintText: 'Enter your password',

              enabledBorder: _error == null
                  ? null
                  : Theme.of(context).inputDecorationTheme.errorBorder,
              focusedBorder: _error == null
                  ? null
                  : Theme.of(context).inputDecorationTheme.focusedErrorBorder,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: context.ink.withValues(alpha: 0.38),
                  size: 20,
                ),
              ),
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
                backgroundColor: Colors.red,
                foregroundColor: context.paper,
                disabledBackgroundColor: Colors.red.withValues(alpha: 0.4),
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
                  : const Text('Delete permanently'),
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
      ),
    );
  }
}
