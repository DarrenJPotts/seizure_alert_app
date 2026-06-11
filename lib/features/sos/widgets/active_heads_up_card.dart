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
      padding: EdgeInsets.all(Dimensions.sixteen),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  'Heads Up active',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Obx(() => Text(
                      'Expires in ${vm.formattedRemaining()}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black45),
                    )),
              ],
            ),
          ),
          SizedBox(width: Dimensions.twelve),
          OutlinedButton(
            onPressed: vm.cancelHeadsUp,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black26),
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.sixteen,
                vertical: Dimensions.eight,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
