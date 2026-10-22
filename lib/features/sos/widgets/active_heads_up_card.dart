import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/heads_up/view_models/heads_up_view_model.dart';

class ActiveHeadsUpCard extends StatelessWidget {
  const ActiveHeadsUpCard({super.key, required this.vm});

  final HeadsUpViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.sixteen),
      decoration: BoxDecoration(
        border: context.designBorder,
        boxShadow: context.designShadows,
        borderRadius: BorderRadius.circular(context.design.cardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Dimensions.four,
              children: [
                Text(
                  'Heads Up active',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: Dimensions.four,
                    children: [
                      Text(
                        'Expires in ${vm.formattedRemaining()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.secondaryInk,
                        ),
                      ),
                      Text(
                        switch (vm.delivery.value) {
                          HeadsUpDelivery.unknown =>
                            'Delivery could not be confirmed after restart. Check with your circle.',
                          HeadsUpDelivery.sending => 'Sending alert…',
                          HeadsUpDelivery.delivered =>
                            'Alert sent to server. Push notifications may take a moment.',
                          HeadsUpDelivery.queued =>
                            'Not confirmed by the server yet. This will keep trying; check with your circle after reconnecting.',
                          HeadsUpDelivery.failed =>
                            'At least one part did not save. Check with your circle before relying on this alert.',
                        },
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.secondaryInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Dimensions.twelve),
          OutlinedButton(
            onPressed: vm.cancelHeadsUp,
            style: OutlinedButton.styleFrom(
              foregroundColor: context.ink,
              side: BorderSide(color: context.ink.withValues(alpha: 0.26)),
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.sixteen,
                vertical: Dimensions.eight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
