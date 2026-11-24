import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:seizure_app/features/heads_up/view_models/heads_up_view_model.dart';

/// Shown to the person with epilepsy while a missed check-in is still open.
/// Their circle was alerted when the Heads Up window ran out; this is how
/// they tell everyone they are okay and close it.
class MissedCheckInCard extends StatelessWidget {
  const MissedCheckInCard({super.key, required this.vm, required this.alert});

  final HeadsUpViewModel vm;
  final AlertDto alert;

  @override
  Widget build(BuildContext context) {
    final String alertedAt = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(alert.createdAt.toLocal()));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.twenty),
      decoration: BoxDecoration(
        color: context.heroSurface,
        borderRadius: BorderRadius.circular(context.design.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'You missed your check-in',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.heroInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Dimensions.eight),
          Text(
            'Your circle was alerted at $alertedAt. Let them know you are okay.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.heroInk,
              height: 1.5,
            ),
          ),
          const SizedBox(height: Dimensions.sixteen),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: vm.confirmingOk.value
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        vm.confirmOk(alert);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.heroInk,
                  foregroundColor: context.heroSurface,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      context.design.cardRadius,
                    ),
                  ),
                ),
                child: Text(
                  vm.confirmingOk.value ? 'Telling your circle…' : "I'm OK",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
