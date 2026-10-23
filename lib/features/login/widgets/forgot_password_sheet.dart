import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/controllers/firebase_auth_controller/firebase_auth_controller.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';

class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key, required this.initialEmail});

  final String initialEmail;

  static Future<void> show(BuildContext context, String initialEmail) =>
      AppBottomSheet.show<void>(
        context: context,
        builder: (_) => ForgotPasswordSheet(initialEmail: initialEmail),
      );

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  late final TextEditingController _emailController;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final result = await FirebaseAuthController.instance().sendPasswordReset(
      _emailController.text,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = result.isSuccess;
      _error = result.error;
    });
  }

  @override
  Widget build(BuildContext context) => AppBottomSheetContent(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          _sent ? 'Check your email' : 'Reset password',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Dimensions.eight),
        Text(
          _sent
              ? 'If an account exists for that address, a password reset link has been sent.'
              : 'Enter your account email and we will send a reset link.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
        ),
        if (!_sent) ...<Widget>[
          const SizedBox(height: Dimensions.sixteen),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
            onSubmitted: (_) => _send(),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: Dimensions.eight),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
            ),
          ],
          const SizedBox(height: Dimensions.twentyFour),
          ElevatedButton(
            onPressed: _sending ? null : _send,
            child: _sending
                ? SizedBox.square(
                    dimension: Dimensions.twenty,
                    child: CircularProgressIndicator(
                      color: context.paper,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Send reset link'),
          ),
        ] else ...<Widget>[
          const SizedBox(height: Dimensions.twentyFour),
          ElevatedButton(onPressed: Get.back<void>, child: const Text('Done')),
        ],
      ],
    ),
  );
}
