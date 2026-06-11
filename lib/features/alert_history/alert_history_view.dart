import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/features/alert_history/view_models/alert_history_view_model.dart';
import 'package:seizure_app/features/alert_history/widgets/alert_detail_sheet.dart';
import 'package:seizure_app/features/alert_history/widgets/alert_history_card.dart';

class AlertHistoryView extends GetView<AlertHistoryViewModel> {
  const AlertHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Alert History',
            style: Theme.of(context).textTheme.titleMedium),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: false,
      ),
      body: Obx(() {
        final state = controller.screenState.value;

        if (state == GenericScreenStates.loading ||
            state == GenericScreenStates.initial) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        if (state == GenericScreenStates.error) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: Dimensions.twelve,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: Colors.black26),
                Text(
                  'Could not load alert history',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          );
        }

        if (state == GenericScreenStates.empty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: Dimensions.twelve,
              children: [
                const Icon(Icons.notifications_none_outlined,
                    size: 48, color: Colors.black26),
                Text(
                  'No alerts sent yet',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(Dimensions.twentyFour),
          itemCount: controller.alerts.length,
          separatorBuilder: (_, _) => SizedBox(height: Dimensions.twelve),
          itemBuilder: (context, index) => AlertHistoryCard(
            alert: controller.alerts[index],
            onTap: () => AlertDetailSheet.show(controller.alerts[index]),
          ),
        );
      }),
    );
  }
}
