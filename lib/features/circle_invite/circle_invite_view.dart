import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/circle_invite/view_models/circle_invite_view_model.dart';

class CircleInviteView extends GetView<CircleInviteViewModel> {
  const CircleInviteView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.paper,
    appBar: AppBar(
      backgroundColor: context.paper,
      elevation: 0,
      foregroundColor: context.ink,
    ),
    body: Obx(() {
      final invite = controller.preview.value;
      return Padding(
        padding: const EdgeInsets.all(Dimensions.twentyFour),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.group_add_outlined, size: 44, color: context.ink),
            const SizedBox(height: Dimensions.twentyFour),
            Text(
              'Enter invite code',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Dimensions.eight),
            Text(
              'Enter the 8-digit code shared with you to join someone’s circle.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.secondaryInk),
            ),
            const SizedBox(height: Dimensions.twentyFour),
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
              const SizedBox(height: Dimensions.eight),
              Text(
                controller.errorMessage.value!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
              ),
            ],
            if (invite != null) ...[
              const SizedBox(height: Dimensions.twentyFour),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.sixteen),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: context.ink.withValues(alpha: 0.12),
                  ),
                  borderRadius: BorderRadius.circular(
                    context.design.cardRadius,
                  ),
                ),
                child: Text(
                  '${invite.senderName} invited you to join their circle as ${invite.contactName}.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: Dimensions.twelve),
              Text(
                'If you accept, you can receive their SOS and Heads Up alerts.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
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
                  child: controller.isLoading.value
                      ? CircularProgressIndicator(color: context.paper)
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
                  child: controller.isResponding.value
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: context.paper,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Accept'),
                ),
              ),
              const SizedBox(height: Dimensions.twelve),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: controller.isResponding.value
                      ? null
                      : () => controller.respond(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.ink,
                    side: BorderSide(
                      color: context.ink.withValues(alpha: 0.26),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: Dimensions.sixteen,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: controller.isResponding.value
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: context.ink,
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
