import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/cycle_tracking_dto.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';
import 'view_models/cycle_view_model.dart';
import 'widgets/cycle_entry_editor.dart';

class CycleView extends StatefulWidget {
  const CycleView({super.key});
  @override
  State<CycleView> createState() => _CycleViewState();
}

class _CycleViewState extends State<CycleView> {
  CycleViewModel get controller => Get.find<CycleViewModel>();
  Future<void> _enable(bool enabled) async {
    HapticFeedback.selectionClick();
    if (enabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: const Text('Enable cycle tracking?'),
          content: const Text(
            'Record period dates, spotting, symptoms and notes to review alongside your seizures. These sensitive details are stored in your private account, are not shown to caregivers or on your Medical card, and are excluded from reports unless you choose to include them. This feature does not measure hormones, predict seizures or diagnose a condition.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await controller.setEnabled(enabled);
  }

  Future<void> _edit([CycleEntryDto? entry]) async {
    HapticFeedback.selectionClick();
    await AppBottomSheet.show(
      context: context,
      builder: (_) => CycleEntryEditor(controller: controller, existing: entry),
    );
  }

  Future<void> _remove(CycleEntryDto? entry) async {
    HapticFeedback.selectionClick();
    final all = entry == null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(
          all ? 'Delete all cycle data?' : 'Remove this period entry?',
        ),
        content: Text(
          all
              ? 'This permanently removes your recorded period dates, flow, symptoms and notes. Your seizure log is unchanged.'
              : 'This permanently removes this period entry, including its symptoms and notes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(all ? 'Delete' : 'Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      if (all) {
        await controller.deleteAll();
      } else {
        await controller.remove(entry.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackButton(),
      title: const Text('Cycle'),
      actions: [
        Obx(
          () => IconButton(
            tooltip: 'Add period entry',
            onPressed:
                controller.data.value.enabled &&
                    !controller.loading.value &&
                    !controller.busy.value
                ? () => _edit()
                : null,
            icon: const Icon(Icons.add),
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
        final data = controller.data.value;
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(Dimensions.twentyFour),
            children: [
              SettingsSection(
                label: 'Private health tracking',
                children: [
                  SettingsSwitchRow(
                    icon: Icons.calendar_month_outlined,
                    title: 'Cycle tracking',
                    subtitle: 'Optional period and spotting diary',
                    value: data.enabled,
                    loading: controller.busy.value,
                    onChanged: _enable,
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.twelve),
              Text(
                'Review recorded periods alongside seizures. Patterns need clinical interpretation; this is not a diagnosis or a prediction.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
              ),
              if (controller.error.value != null) ...[
                const SizedBox(height: Dimensions.sixteen),
                Text(controller.error.value!),
                TextButton(
                  onPressed: controller.busy.value ? null : controller.load,
                  child: const Text('Refresh cycle tracking'),
                ),
              ],
              if (data.enabled) ...[
                const SizedBox(height: Dimensions.twentyFour),
                OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Get.toNamed(AppRoutes.analytics);
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('View calendar in Insights'),
                ),
                const SizedBox(height: Dimensions.twentyFour),
                Text(
                  'Period entries',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: Dimensions.twelve),
                if (data.entries.isEmpty)
                  const Text(
                    'No periods recorded yet. Add dates you know; irregular cycles are welcome.',
                  ),
                const SizedBox(height: Dimensions.twelve),
                OutlinedButton.icon(
                  onPressed: controller.busy.value ? null : () => _edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add period entry'),
                ),
                for (final entry in data.entries) ...[
                  const SizedBox(height: Dimensions.sixteen),
                  Container(
                    padding: const EdgeInsets.all(Dimensions.sixteen),
                    decoration: BoxDecoration(
                      color: context.cardSurface,
                      border: context.designBorder,
                      borderRadius: BorderRadius.circular(
                        context.design.cardRadius,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${MaterialLocalizations.of(context).formatMediumDate(entry.start)} – ${entry.end == null ? 'Ongoing' : MaterialLocalizations.of(context).formatMediumDate(entry.end!)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: Dimensions.eight),
                        Text('Flow: ${entry.flow.label}'),
                        if (entry.symptoms.isNotEmpty) ...[
                          const SizedBox(height: Dimensions.eight),
                          Text(entry.symptoms),
                        ],
                        if (entry.notes.isNotEmpty) ...[
                          const SizedBox(height: Dimensions.eight),
                          Text(entry.notes),
                        ],
                        Wrap(
                          spacing: Dimensions.twelve,
                          children: [
                            TextButton(
                              onPressed: controller.busy.value
                                  ? null
                                  : () => _edit(entry),
                              child: const Text('Edit'),
                            ),
                            TextButton(
                              onPressed: controller.busy.value
                                  ? null
                                  : () => _remove(entry),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                const SizedBox(height: Dimensions.twentyFour),
                const Text(
                  'Enable tracking to add period entries and see your private calendar. Turning tracking off keeps existing entries until you delete them.',
                ),
              ],
              if (data.entries.isNotEmpty) ...[
                const SizedBox(height: Dimensions.twentyFour),
                TextButton.icon(
                  onPressed: controller.busy.value ? null : () => _remove(null),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete all cycle data'),
                ),
              ],
            ],
          ),
        );
      }),
    ),
  );
}
