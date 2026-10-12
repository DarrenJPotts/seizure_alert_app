import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/circle_invite/view_models/circle_invite_view_model.dart';

class CircleInviteView extends GetView<CircleInviteViewModel> {
  const CircleInviteView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black,
    ),
    body: Obx(() {
      final invite = controller.preview.value;
      return Padding(
        padding: EdgeInsets.all(Dimensions.twentyFour),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.group_add_outlined, size: 44, color: Colors.black),
            SizedBox(height: Dimensions.twentyFour),
            Text(
              'Enter invite code',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: Dimensions.eight),
            Text(
              'Enter the 8-digit code shared with you to join someone’s circle.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
            SizedBox(height: Dimensions.twentyFour),
            TextField(
              controller: controller.codeController,
              textCapitalization: TextCapitalization.characters,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.center,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9A-Fa-f]')),
                LengthLimitingTextInputFormatter(32),
              ],
              decoration: const InputDecoration(
                labelText: 'Invite code',
                hintText: '00000000',
              ),
              onChanged: (_) {
                if (controller.preview.value != null) {
                  controller.preview.value = null;
                }
              },
            ),
            if (controller.errorMessage.value != null) ...[
              SizedBox(height: Dimensions.eight),
              Text(
                controller.errorMessage.value!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
              ),
            ],
            if (invite != null) ...[
              SizedBox(height: Dimensions.twentyFour),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(Dimensions.sixteen),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${invite.senderName} invited you to join their circle as ${invite.contactName}.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              SizedBox(height: Dimensions.twelve),
              Text(
                'If you accept, you can receive their SOS and Heads Up alerts.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
            const Spacer(),
            if (invite == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.lookUpCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: Dimensions.sixteen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Continue'),
                ),
              )
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isResponding.value
                      ? null
                      : () => controller.respond(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: Dimensions.sixteen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isResponding.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Accept'),
                ),
              ),
              SizedBox(height: Dimensions.twelve),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: controller.isResponding.value
                      ? null
                      : () => controller.respond(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black26),
                    padding: EdgeInsets.symmetric(vertical: Dimensions.sixteen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: controller.isResponding.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Decline'),
                ),
              ),
            ],
          ],
        ),
      );
    }),
  );
}
