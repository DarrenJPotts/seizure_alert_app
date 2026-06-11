import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/profile/view_models/profile_view_model.dart';

class DeleteAccountSheet extends StatefulWidget {
  const DeleteAccountSheet({super.key});

  static Future<void> show() => showModalBottomSheet(
        context: Get.context!,
        backgroundColor: Colors.white,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (_) => const DeleteAccountSheet(),
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

    final result =
        await Get.find<ProfileViewModel>().deleteAccount(password);

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _isBusy = false;
        _error = result.error;
      });
    }
    // On success the auth controller navigates to login automatically —
    // no need to pop the sheet manually.
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(Dimensions.twentyFour),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──────────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: EdgeInsets.only(bottom: Dimensions.twentyFour),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(Dimensions.circular),
                ),
              ),
            ),

            // ── Title ───────────────────────────────────────────────────
            Text('Delete Account',
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: Dimensions.twelve),

            // ── Warning ─────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(Dimensions.sixteen),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Text(
                'This will permanently delete your account, medical profile, seizure log, contacts, and all alert history. This cannot be undone.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.red.shade700),
              ),
            ),
            SizedBox(height: Dimensions.twentyFour),

            // ── Password field ───────────────────────────────────────────
            Text(
              'Confirm your password',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600, color: Colors.black54),
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
                hintStyle:
                    const TextStyle(color: Colors.black26, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
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
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.red),
              ),
            ],
            SizedBox(height: Dimensions.twentyFour),

            // ── Delete button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBusy ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.red.withValues(alpha: 0.4),
                  padding:
                      EdgeInsets.symmetric(vertical: Dimensions.sixteen),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isBusy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Delete permanently'),
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
        ),
      ),
    );
  }
}
