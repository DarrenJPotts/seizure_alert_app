import 'package:seizure_app/features/home/widgets/upcoming_reminder_card.dart';
import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/features/home/view_models/home_view_model.dart';
import 'package:seizure_app/features/home/widgets/activity_grid.dart';
import 'package:seizure_app/features/home/widgets/greeting_widget.dart';
import 'package:seizure_app/features/home/widgets/days_free_card.dart';
import 'package:seizure_app/features/home/widgets/setup_check_card.dart';
import 'package:seizure_app/features/home/widgets/stat_chip.dart';

class HomeView extends GetView<HomeViewModel> {
  const HomeView({super.key, required this.onOpenContacts});

  final VoidCallback onOpenContacts;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.twentyFour),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 320 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3;
              void openInsights() {
                HapticFeedback.selectionClick();
                Get.toNamed(AppRoutes.analytics);
              }

              return Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => GreetingWidget(
                        greeting: controller.greeting,
                        name: controller.firstName,
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.twelve),
                  if (compact)
                    IconButton(
                      onPressed: openInsights,
                      tooltip: 'View insights',
                      icon: const Icon(Icons.insights_outlined),
                    )
                  else
                    TextButton(
                      onPressed: openInsights,
                      child: const Text('View insights'),
                    ),
                ],
              );
            },
          ),
          SetupCheckCard(
            onTap: onOpenContacts,
            spacingBefore: context.design.sectionGap,
          ),
          const UpcomingReminderCard(),
          Padding(
            padding: EdgeInsets.only(top: context.design.sectionGap),
            child: Obx(() {
              final _ = controller.seizureLogs.length;
              final state = controller.screenState.value;
              final loading =
                  state == GenericScreenStates.loading ||
                  state == GenericScreenStates.initial;

              if (loading) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: context.ink),
                  ),
                );
              }

              if (state == GenericScreenStates.error) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your seizure history could not be loaded.'),
                    TextButton(
                      onPressed: controller.retry,
                      child: const Text('Retry'),
                    ),
                  ],
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
          ),
        ],
      ),
    );
  }
}
