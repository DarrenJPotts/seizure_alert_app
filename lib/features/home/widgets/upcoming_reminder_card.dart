import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:seizure_app/features/reminders/view_models/reminders_view_model.dart';
import '../models/home_reminder_summary.dart';

class UpcomingReminderCard extends StatelessWidget {
  const UpcomingReminderCard({super.key, this.onOpen});
  final VoidCallback? onOpen;
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<RemindersViewModel>()) return const SizedBox.shrink();
    final controller = Get.find<RemindersViewModel>();
    return Obx(() {
      final now = controller.now.value;
      final item = homeReminderSummary(controller.reminders.toList(), now);
      final loading = controller.loading.value;
      final failed = controller.error.value != null;
      final title = loading || failed || item == null
          ? 'Reminders'
          : !item.at.isAfter(now)
          ? 'Reminder due'
          : 'Next reminder';
      final text = Theme.of(context).textTheme;
      return Padding(
        padding: EdgeInsets.only(top: context.design.sectionGap),
        child: Material(
          color: context.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.design.cardRadius),
            side: BorderSide(
              color: context.ink.withValues(
                alpha: context.design.borderOpacity,
              ),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              if (onOpen != null) {
                onOpen!();
              } else {
                Get.toNamed(AppRoutes.reminders);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.twenty),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: Dimensions.four),
                    child: Icon(Icons.notifications_active_outlined),
                  ),
                  const SizedBox(width: Dimensions.twelve),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: text.bodySmall?.copyWith(
                            color: context.secondaryInk,
                          ),
                        ),
                        const SizedBox(height: Dimensions.four),
                        Text(
                          loading
                              ? 'Loading reminders…'
                              : failed
                              ? 'Open reminders to retry'
                              : item == null
                              ? 'No upcoming reminders'
                              : item.reminder.name,
                          style: text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!loading && !failed && item != null) ...[
                          const SizedBox(height: Dimensions.four),
                          Text(
                            '${item.snoozed ? 'Snoozed · ' : ''}${_when(context, item.at, now)}',
                            style: text.bodySmall?.copyWith(
                              color: context.secondaryInk,
                            ),
                          ),
                        ],
                        const SizedBox(height: Dimensions.twelve),
                        Text(
                          'View reminders',
                          style: text.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!loading &&
                            controller.notificationWarning.value != null) ...[
                          const SizedBox(height: Dimensions.eight),
                          Text(
                            'Check reminder notifications',
                            style: text.bodySmall?.copyWith(
                              color: context.secondaryInk,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: Dimensions.eight),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  String _when(BuildContext context, DateTime at, DateTime now) {
    final date = DateTime(at.year, at.month, at.day);
    final today = DateTime(now.year, now.month, now.day);
    final day = date == today
        ? 'Today'
        : date == DateTime(now.year, now.month, now.day + 1)
        ? 'Tomorrow'
        : MaterialLocalizations.of(context).formatMediumDate(at);
    return '$day · ${TimeOfDay.fromDateTime(at).format(context)}';
  }
}
