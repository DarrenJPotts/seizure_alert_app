import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/features/home/view_models/home_view_model.dart';
import 'package:seizure_app/features/home/widgets/activity_grid.dart';
import 'package:seizure_app/features/home/widgets/days_free_card.dart';
import 'package:seizure_app/features/home/widgets/greeting_widget.dart';
import 'package:seizure_app/features/home/widgets/stat_chip.dart';

class HomeView extends GetView<HomeViewModel> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Dimensions.twentyFour),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Dimensions.twentyFour,
        children: [
          Obx(() => GreetingWidget(
                greeting: controller.greeting,
                name: controller.firstName,
              )),
          Obx(() {
            final _ = controller.seizureLogs.length;
            final state = controller.screenState.value;
            final loading = state == GenericScreenStates.loading ||
                state == GenericScreenStates.initial;

            if (loading) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.black),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Dimensions.sixteen,
              children: [
                DaysFreeCard(days: controller.daysSinceLastSeizure),
                Row(
                  spacing: Dimensions.twelve,
                  children: [
                    Expanded(
                      child: StatChip(
                        label: 'Last 7 days',
                        value: controller.last7DaysCount,
                      ),
                    ),
                    Expanded(
                      child: StatChip(
                        label: 'This month',
                        value: controller.thisMonthCount,
                      ),
                    ),
                  ],
                ),
                ActivityGrid(cells: controller.gridData),
              ],
            );
          }),
        ],
      ),
    );
  }
}
