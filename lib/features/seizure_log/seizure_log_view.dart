import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';
import 'package:seizure_app/core/widgets/settings/settings_screen_header.dart';
import 'package:seizure_app/features/seizure_log/view_models/seizure_log_view_model.dart';
import 'package:seizure_app/features/seizure_log/widgets/add_seizure_log_bottom_sheet.dart';
import 'package:seizure_app/features/seizure_log/widgets/seizure_log_row.dart';
import 'package:seizure_app/features/seizure_log/widgets/seizure_calendar_summary.dart';

class SeizureLogView extends GetView<SeizureLogViewModel> {
  const SeizureLogView({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SettingsScreenHeader(
        title: 'Seizure log',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Obx(
              () => IconButton(
                tooltip: 'Share clinical report',
                onPressed: controller.exporting.value
                    ? null
                    : () => _shareReport(context),
                icon: controller.exporting.value
                    ? SizedBox.square(
                        dimension: Dimensions.eighteen,
                        child: CircularProgressIndicator(
                          color: context.ink,
                          strokeWidth: 1.5,
                        ),
                      )
                    : const Icon(Icons.ios_share_outlined),
              ),
            ),
            TextButton.icon(
              onPressed: _openAddSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add entry'),
              style: TextButton.styleFrom(foregroundColor: context.ink),
            ),
          ],
        ),
      ),
      Expanded(
        child: Obx(() {
          final GenericScreenStates state = controller.screenState.value;

          if (state == GenericScreenStates.loading ||
              state == GenericScreenStates.initial) {
            return Center(child: CircularProgressIndicator(color: context.ink));
          }

          if (state == GenericScreenStates.error) {
            return const SettingsScreenPlaceholder(
              icon: Icons.error_outline,
              message: 'Could not load your seizure log',
            );
          }

          final List<SeizureLogDto> logs = controller.logs;

          if (logs.isEmpty) {
            return SettingsScreenPlaceholder(
              icon: Icons.bolt_outlined,
              message: 'No seizures logged yet',
              detail:
                  'Entries are added automatically when you send an SOS, or you can add one yourself.',
              action: TextButton(
                onPressed: _openAddSheet,
                style: TextButton.styleFrom(foregroundColor: context.ink),
                child: const Text('Add your first entry'),
              ),
            );
          }

          final List<_LogMonth> months = _groupByMonth(logs);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.twenty,
              Dimensions.twentyTwo,
              Dimensions.twenty,
              Dimensions.twentyFour,
            ),
            children: <Widget>[
              SeizureCalendarSummary(logs: logs),
              const SizedBox(height: Dimensions.twentySix),
              for (
                int index = 0;
                index < months.length;
                index += 1
              ) ...<Widget>[
                SettingsSection(
                  label:
                      '${months[index].label}  ·  ${_countLabel(months[index].entries.length)}',
                  children: <Widget>[
                    for (final SeizureLogDto log in months[index].entries)
                      _DismissibleLogRow(
                        log: log,
                        onTap: () => _openAddSheet(existing: log),
                        onDelete: () => controller.deleteEntry(log.id),
                      ),
                  ],
                ),
                if (index < months.length - 1)
                  const SizedBox(height: Dimensions.twentySix),
              ],
            ],
          );
        }),
      ),
    ],
  );

  void _openAddSheet({SeizureLogDto? existing}) =>
      AddSeizureLogBottomSheet.show(
        onAdd: controller.addEntry,
        onUpdate: controller.updateEntry,
        existingLog: existing,
      );

  Future<void> _shareReport(BuildContext context) async {
    HapticFeedback.selectionClick();
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final String? error = await controller.shareReport(
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    );
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  static String _countLabel(int count) =>
      count == 1 ? '1 entry' : '$count entries';

  static List<_LogMonth> _groupByMonth(List<SeizureLogDto> logs) {
    final List<_LogMonth> months = <_LogMonth>[];

    for (final SeizureLogDto log in logs) {
      final DateTime at = log.occurredAt;
      final bool sameAsLast =
          months.isNotEmpty &&
          months.last.year == at.year &&
          months.last.month == at.month;

      if (!sameAsLast) {
        months.add(
          _LogMonth(year: at.year, month: at.month, label: formatLogMonth(at)),
        );
      }
      months.last.entries.add(log);
    }

    return months;
  }
}

class _LogMonth {
  _LogMonth({required this.year, required this.month, required this.label});

  final int year;
  final int month;
  final String label;
  final List<SeizureLogDto> entries = <SeizureLogDto>[];
}

class _DismissibleLogRow extends StatelessWidget {
  const _DismissibleLogRow({
    required this.log,
    required this.onTap,
    required this.onDelete,
  });

  final SeizureLogDto log;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey<String>(log.id),
    direction: DismissDirection.endToStart,
    background: ColoredBox(
      color: Colors.red.shade50,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: Dimensions.twenty),
          child: Icon(Icons.delete_outline, color: Colors.red.shade400),
        ),
      ),
    ),
    confirmDismiss: (DismissDirection _) async {
      HapticFeedback.selectionClick();
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          backgroundColor: context.paper,
          title: const Text('Remove this entry?'),
          content: const Text(
            'It will be permanently deleted from your seizure log.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirmed != true) return false;
      return onDelete();
    },
    child: SeizureLogRow(log: log, onTap: onTap),
  );
}
