import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/invite_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/features/circle_invite/view_models/circle_invite_view_model.dart';

class CircleInviteView extends GetView<CircleInviteViewModel> {
  const CircleInviteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Obx(() {
        final state = controller.screenState.value;

        if (state == GenericScreenStates.loading ||
            state == GenericScreenStates.initial) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        final invite = controller.invite.value;
        if (state == GenericScreenStates.error || invite == null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(Dimensions.twentyFour),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: Dimensions.twelve,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.black26),
                  Text(
                    'This invite is no longer available',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (invite.status != InviteStatus.pending) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(Dimensions.twentyFour),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: Dimensions.twelve,
                children: [
                  const Icon(Icons.check_circle_outline, size: 48, color: Colors.black26),
                  Text(
                    "You've already responded to this invite",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(Dimensions.twentyFour),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.group_add_outlined, size: 48, color: Colors.black),
              SizedBox(height: Dimensions.twentyFour),
              Text(
                '${invite.senderName} wants to add you to their circle',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: Dimensions.twelve),
              Text(
                "If they send an SOS or Heads Up alert, you'll be notified so you can check on them.",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black54),
              ),
              const Spacer(),
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          controller.isResponding.value ? null : () => controller.respond(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        disabledBackgroundColor: Colors.black38,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: Dimensions.sixteen),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Accept'),
                    ),
                  )),
              SizedBox(height: Dimensions.twelve),
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed:
                          controller.isResponding.value ? null : () => controller.respond(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black26),
                        padding: EdgeInsets.symmetric(vertical: Dimensions.sixteen),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Decline'),
                    ),
                  )),
            ],
          ),
        );
      }),
    );
  }
}
