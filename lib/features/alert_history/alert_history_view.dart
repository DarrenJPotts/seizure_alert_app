import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/widgets/settings/settings_screen_header.dart';
import 'package:seizure_app/features/alert_history/view_models/alert_history_view_model.dart';
import 'package:seizure_app/features/alert_history/widgets/alert_detail_sheet.dart';
import 'package:seizure_app/features/alert_history/widgets/alert_history_card.dart';

class AlertHistoryView extends GetView<AlertHistoryViewModel> {
  const AlertHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final Widget content = _buildContent(context);

    if (controller.caregiverMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SettingsScreenHeader(title: 'Alerts'),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      backgroundColor: context.paper,
      appBar: AppBar(
        title: Text(
          'Alert History',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        backgroundColor: context.paper,
        elevation: 0,
        foregroundColor: context.ink,
        centerTitle: false,
      ),
      body: content,
    );
  }

  Widget _buildContent(BuildContext context) => Obx(() {
    final state = controller.screenState.value;

    if (state == GenericScreenStates.loading ||
        state == GenericScreenStates.initial) {
      return Center(child: CircularProgressIndicator(color: context.ink));
    }

    if (state == GenericScreenStates.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: Dimensions.twelve,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: context.ink.withValues(alpha: 0.26),
            ),
            Text(
              'Could not load alert history',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.secondaryInk),
            ),
            if (controller.caregiverMode)
              OutlinedButton(
                onPressed: controller.reload,
                child: const Text('Try again'),
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
            Icon(
              Icons.notifications_none_outlined,
              size: 48,
              color: context.ink.withValues(alpha: 0.26),
            ),
            Text(
              controller.caregiverMode
                  ? 'No alerts received yet'
                  : 'No alerts sent yet',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.secondaryInk),
            ),
            if (controller.caregiverMode)
              TextButton(
                onPressed: controller.reload,
                child: const Text('Refresh'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.reload,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Dimensions.twentyFour),
        itemCount: controller.alerts.length,
        separatorBuilder: (_, _) => const SizedBox(height: Dimensions.twelve),
        itemBuilder: (context, index) {
          final alert = controller.alerts[index];
          return AlertHistoryCard(
            alert: alert,
            onTap: () => controller.caregiverMode
                ? Get.toNamed(
                    AppRoutes.incomingAlert,
                    arguments: <String, String>{'alertId': alert.id},
                  )
                : AlertDetailSheet.show(alert),
          );
        },
      ),
    );
  });
}
