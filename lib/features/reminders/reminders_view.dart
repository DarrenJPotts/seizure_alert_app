import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/medication_reminder_dto.dart';
import 'package:seizure_app/core/helpers/reminder_schedule.dart';
import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:seizure_app/features/reminders/view_models/reminders_view_model.dart';
import 'package:seizure_app/features/reminders/widgets/reminder_editor.dart';

class RemindersView extends StatefulWidget {
  const RemindersView({super.key});
  @override
  State<RemindersView> createState() => _RemindersViewState();
}

class _RemindersViewState extends State<RemindersView> {
  RemindersViewModel get controller => Get.find<RemindersViewModel>();
  bool _history = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Reminders'),
      actions: [
        Obx(
          () => IconButton(
            tooltip: 'Add reminder',
            icon: const Icon(Icons.add),
            onPressed: controller.loading.value || controller.busy.value
                ? null
                : () => _edit(),
          ),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Dimensions.twentyFour),
            children: [
              Text(
                'Your schedule',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: Dimensions.eight),
              const Text(
                'Times follow this phone’s time zone. Notifications may be delayed by phone settings. Record an action when a reminder is due.',
              ),
              const SizedBox(height: Dimensions.sixteen),
              Wrap(
                spacing: Dimensions.eight,
                runSpacing: Dimensions.eight,
                children: [
                  ChoiceChip(
                    label: const Text('Reminders'),
                    selected: !_history,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _history = false);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('History'),
                    selected: _history,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _history = true);
                    },
                  ),
                ],
              ),
              if (controller.error.value != null) ...[
                const SizedBox(height: Dimensions.sixteen),
                Text(controller.error.value!),
                TextButton(
                  onPressed: controller.busy.value ? null : controller.load,
                  child: const Text('Refresh reminders'),
                ),
              ],
              if (controller.notificationWarning.value != null) ...[
                const SizedBox(height: Dimensions.sixteen),
                Text(controller.notificationWarning.value!),
                TextButton(
                  onPressed: controller.busy.value ? null : controller.load,
                  child: const Text('Retry notifications'),
                ),
              ],
              const SizedBox(height: Dimensions.twentyFour),
              if (_history)
                ..._historyItems(context)
              else if (controller.reminders.isEmpty) ...[
                const Text(
                  'No reminders yet. Add medication, vitamins, an appointment, or a personal reminder.',
                ),
                const SizedBox(height: Dimensions.sixteen),
                OutlinedButton.icon(
                  onPressed: controller.busy.value ? null : () => _edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add reminder'),
                ),
              ] else
                for (final reminder in controller.reminders) ...[
                  _card(context, reminder),
                  const SizedBox(height: Dimensions.sixteen),
                ],
            ],
          ),
        );
      }),
    ),
  );

  Widget _card(BuildContext context, MedicationReminderDto reminder) {
    final now = controller.now.value;
    final due = actionableReminderOccurrence(reminder, now);
    final next = nextReminderOccurrence(reminder, now);
    final snoozing =
        due != null &&
        reminder.snoozedUntil?.isAfter(now) == true &&
        reminder.snoozedOccurrence == reminderOccurrenceKey(due);
    return Container(
      padding: const EdgeInsets.all(Dimensions.sixteen),
      decoration: BoxDecoration(
        color: context.cardSurface,
        border: context.designBorder,
        borderRadius: BorderRadius.circular(context.design.cardRadius),
        boxShadow: context.designShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Dimensions.twelve,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      reminder.kindLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: reminder.enabled,
                onChanged: controller.busy.value
                    ? null
                    : (enabled) {
                        HapticFeedback.selectionClick();
                        controller.setEnabled(reminder, enabled);
                      },
              ),
              PopupMenuButton<String>(
                tooltip: 'Reminder options',
                enabled: !controller.busy.value,
                onSelected: (value) {
                  HapticFeedback.selectionClick();
                  if (value == 'edit') {
                    _edit(reminder);
                  } else {
                    _remove(reminder);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'remove', child: Text('Remove')),
                ],
              ),
            ],
          ),
          if (reminder.isMedicine && reminder.dose?.isNotEmpty == true)
            Text(reminder.dose!),
          Text(reminderScheduleLabel(reminder)),
          if (!reminder.enabled)
            const Text('Off')
          else if (snoozing)
            Text('Snoozed until ${_at(reminder.snoozedUntil!.toLocal())}')
          else if (next != null)
            Text('Next: ${_at(next)}'),
          if (due != null) ...[
            Text('Scheduled: ${_at(due)} · no completion recorded'),
            Wrap(
              spacing: Dimensions.eight,
              runSpacing: Dimensions.eight,
              children: [
                TextButton(
                  onPressed: controller.busy.value
                      ? null
                      : () => _record(reminder, ReminderAction.completed),
                  child: Text(
                    reminder.isMedicine ? 'Mark taken' : 'Mark completed',
                  ),
                ),
                TextButton(
                  onPressed: controller.busy.value
                      ? null
                      : () => _record(reminder, ReminderAction.skipped),
                  child: const Text('Skip'),
                ),
                if (!snoozing)
                  TextButton(
                    onPressed: controller.busy.value
                        ? null
                        : () => _snooze(reminder),
                    child: const Text('Snooze'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _historyItems(BuildContext context) {
    final events = [
      for (final reminder in controller.reminders)
        for (final event in reminder.history)
          (reminder: reminder, event: event),
    ]..sort((a, b) => b.event.at.compareTo(a.event.at));
    return [
      const Text(
        'Actions you recorded. An unrecorded reminder does not confirm a missed dose. The latest 100 actions per reminder are kept.',
      ),
      const SizedBox(height: Dimensions.sixteen),
      if (events.isEmpty) const Text('No actions recorded yet.'),
      for (final item in events) ...[
        Text(
          item.reminder.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '${switch (item.event.action) {
            ReminderAction.completed => item.reminder.isMedicine ? 'Taken' : 'Completed',
            ReminderAction.skipped => 'Skipped',
            ReminderAction.snoozed => 'Snoozed',
          }} · ${_at(item.event.at.toLocal())}',
        ),
        Text(
          'Scheduled for ${_at(DateTime.parse(item.event.occurrence))}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Divider(height: Dimensions.thirtyTwo),
      ],
    ];
  }

  Future<void> _edit([MedicationReminderDto? reminder]) async {
    HapticFeedback.selectionClick();
    await AppBottomSheet.show<void>(
      context: context,
      builder: (_) =>
          ReminderEditor(controller: controller, existing: reminder),
    );
  }

  Future<void> _remove(MedicationReminderDto reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove reminder?'),
        content: const Text(
          'This removes the reminder and its recorded history. Notifications will stop on this phone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await controller.remove(reminder);
  }

  Future<void> _record(
    MedicationReminderDto reminder,
    ReminderAction action,
  ) async {
    HapticFeedback.selectionClick();
    await controller.record(reminder, action);
  }

  Future<void> _snooze(MedicationReminderDto reminder) async {
    HapticFeedback.selectionClick();
    final minutes = await AppBottomSheet.show<int>(
      context: context,
      builder: (context) => AppBottomSheetContent(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Dimensions.twelve,
          children: [
            Text(
              'Snooze reminder',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final minutes in [5, 15, 30, 60])
              OutlinedButton(
                onPressed: () => Navigator.pop(context, minutes),
                child: Text('$minutes minutes'),
              ),
          ],
        ),
      ),
    );
    if (minutes != null && mounted) {
      await controller.record(
        reminder,
        ReminderAction.snoozed,
        snoozeMinutes: minutes,
      );
    }
  }
}

String _at(DateTime at) =>
    '${at.day}/${at.month}/${at.year} ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
