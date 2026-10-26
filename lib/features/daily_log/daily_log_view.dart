import 'widgets/daily_week_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/dimensions.dart';
import '../../core/dtos/daily_log_dto.dart';
import '../../core/enums/generic_screen_states.dart';
import '../../core/routes/app_routes.dart';
import '../../core/themes/app_palette.dart';
import '../../core/widgets/bottom_sheet/app_bottom_sheet.dart';
import '../cycle/view_models/cycle_view_model.dart';
import '../cycle/widgets/cycle_entry_editor.dart';
import '../seizure_log/widgets/clinical_report_action.dart';
import '../seizure_log/widgets/daily_seizure_row.dart';
import '../seizure_log/view_models/seizure_log_view_model.dart';
import '../seizure_log/widgets/add_seizure_log_bottom_sheet.dart';
import 'view_models/daily_log_view_model.dart';
import 'widgets/daily_check_in_form.dart';

class DailyLogView extends StatefulWidget {
  const DailyLogView({super.key});
  @override
  State<DailyLogView> createState() => _DailyLogViewState();
}

class _DailyLogViewState extends State<DailyLogView> {
  final form = GlobalKey<DailyCheckInFormState>();
  late final DailyLogViewModel daily = Get.find<DailyLogViewModel>();
  late final SeizureLogViewModel seizures = Get.find<SeizureLogViewModel>();
  @override
  void initState() {
    super.initState();
    daily.confirmDateChange = _confirm;
  }

  @override
  void dispose() {
    daily.confirmDateChange = null;
    super.dispose();
  }

  Future<bool> _confirm() async {
    if (form.currentState?.dirty != true) {
      return true;
    }
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard daily changes?'),
            content: const Text(
              'Your unsaved daily check-in will be discarded.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ==
        true;
  }

  Future<void> _pick() async {
    HapticFeedback.selectionClick();
    final date = await showDatePicker(
      context: context,
      initialDate: daily.selectedDate.value,
      firstDate: DateTime(1900),
      lastDate: daily.today,
    );
    if (date != null) {
      await daily.selectDate(date);
    }
  }

  void _add() {
    HapticFeedback.selectionClick();
    final day = daily.selectedDate.value;
    final now = DateTime.now();
    AddSeizureLogBottomSheet.show(
      onAdd: seizures.addEntry,
      onUpdate: seizures.updateEntry,
      initialOccurredAt: DateTime(
        day.year,
        day.month,
        day.day,
        now.hour,
        now.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final day = daily.selectedDate.value;
    final events = seizures.logs
        .where((e) => dailyDate(e.occurredAt.toLocal()) == day)
        .toList();
    final state = seizures.screenState.value;
    return ListView(
      padding: const EdgeInsets.all(Dimensions.twentyFour),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Dimensions.eight,
          children: [
            Text('Daily log', style: Theme.of(context).textTheme.headlineSmall),
            Wrap(
              children: [
                TextButton(
                  onPressed: daily.saving.value
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          daily.selectDate(daily.today);
                        },
                  child: const Text('Today'),
                ),
                IconButton(
                  tooltip: 'Choose date',
                  onPressed: daily.saving.value ? null : _pick,
                  icon: const Icon(Icons.calendar_today_outlined),
                ),
                IconButton(
                  tooltip: 'Share clinical report',
                  onPressed: seizures.exporting.value
                      ? null
                      : () => shareClinicalReport(context, seizures),
                  icon: const Icon(Icons.ios_share_outlined),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Daily log options',
                  onSelected: (value) {
                    HapticFeedback.selectionClick();
                    Get.toNamed(
                      value == 'cycle' ? AppRoutes.cycle : AppRoutes.analytics,
                    );
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'insights',
                      child: Text('Calendar & Insights'),
                    ),
                    const PopupMenuItem(
                      value: 'cycle',
                      child: Text('Cycle settings'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: Dimensions.sixteen),
        DailyWeekSelector(
          selectedDate: day,
          today: daily.today,
          enabled: !daily.saving.value,
          onSelect: daily.selectDate,
        ),
        const SizedBox(height: Dimensions.twelve),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: const Text('Add seizure'),
          ),
        ),
        const SizedBox(height: Dimensions.twentyFour),
        if (daily.loading.value)
          const Center(child: CircularProgressIndicator())
        else if (daily.error.value != null &&
            daily.entry.value == null &&
            form.currentState?.dirty != true)
          _section(context, 'Daily check-in', [
            Text(daily.error.value!),
            TextButton(
              onPressed: daily.load,
              child: const Text('Refresh daily entry'),
            ),
          ])
        else
          DailyCheckInForm(
            key: form,
            controller: daily,
            date: day,
            entry: daily.entry.value,
            hasSeizures: events.isNotEmpty,
          ),
        const SizedBox(height: Dimensions.twentyFour),
        _section(context, 'Seizures', [
          if (state == GenericScreenStates.loading ||
              state == GenericScreenStates.initial)
            const LinearProgressIndicator()
          else if (state == GenericScreenStates.error)
            const Text(
              'Could not load seizure entries. Try again from Insights.',
            )
          else if (events.isEmpty)
            Text(
              daily.entry.value?.noSeizuresReported == true
                  ? 'You reported no seizures for this day.'
                  : 'No seizure entries recorded for this day.',
            ),
          for (final event in events)
            DailySeizureRow(
              log: event,
              onTap: () => AddSeizureLogBottomSheet.show(
                onAdd: seizures.addEntry,
                onUpdate: seizures.updateEntry,
                existingLog: event,
              ),
              onDelete: () => seizures.deleteEntry(event.id),
            ),
        ]),
        if (Get.isRegistered<CycleViewModel>())
          Obx(() {
            final cycle = Get.find<CycleViewModel>();
            if (cycle.loading.value || !cycle.data.value.enabled) {
              return const SizedBox.shrink();
            }
            final entries = cycle.data.value.entries
                .where((e) => e.contains(day, daily.today))
                .toList();
            return Padding(
              padding: const EdgeInsets.only(top: Dimensions.twentyFour),
              child: _section(context, 'Cycle', [
                Text(
                  cycle.error.value != null
                      ? 'Cycle data could not be refreshed.'
                      : entries.isEmpty
                      ? 'No period or spotting recorded for this day.'
                      : 'Period or spotting recorded for this day.',
                ),
                TextButton.icon(
                  onPressed: cycle.busy.value
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          AppBottomSheet.show(
                            context: context,
                            builder: (_) => CycleEntryEditor(
                              controller: cycle,
                              existing: entries.firstOrNull,
                              initialDate: day,
                            ),
                          );
                        },
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(
                    entries.isEmpty
                        ? 'Add period / spotting'
                        : 'Edit period entry',
                  ),
                ),
              ]),
            );
          }),
        const SizedBox(height: Dimensions.twentyFour),
        Text(
          'Daily check-ins are private. They are excluded from your Medical card and clinical reports.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
        ),
      ],
    );
  });
  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(Dimensions.twenty),
        decoration: BoxDecoration(
          color: context.cardSurface,
          border: context.designBorder,
          borderRadius: BorderRadius.circular(context.design.cardRadius),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Dimensions.twelve),
              ...children,
            ],
          ),
        ),
      );
}
