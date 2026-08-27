import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';
import 'package:seizure_app/core/widgets/settings/settings_screen_header.dart';
import 'package:seizure_app/features/seizure_log/view_models/seizure_log_view_model.dart';
import 'package:seizure_app/features/seizure_log/widgets/add_seizure_log_bottom_sheet.dart';
import 'package:seizure_app/features/seizure_log/widgets/seizure_log_row.dart';

class SeizureLogView extends GetView<SeizureLogViewModel> {
  const SeizureLogView({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SettingsScreenHeader(
        title: 'Seizure log',
        trailing: TextButton.icon(
          onPressed: _openAddSheet,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add entry'),
          style: TextButton.styleFrom(foregroundColor: Colors.black),
        ),
      ),
      Expanded(
        child: Obx(() {
          final GenericScreenStates state = controller.screenState.value;

          if (state == GenericScreenStates.loading || state == GenericScreenStates.initial) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
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
              detail: 'Entries are added automatically when you send an SOS, or you can add one yourself.',
              action: TextButton(
                onPressed: _openAddSheet,
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text('Add your first entry'),
              ),
            );
          }

          final List<_LogMonth> months = _groupByMonth(logs);

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              Dimensions.twenty,
              Dimensions.twentyTwo,
              Dimensions.twenty,
              Dimensions.twentyFour,
            ),
            itemCount: months.length,
            separatorBuilder: (BuildContext _, int _) => SizedBox(height: Dimensions.twentySix),
            itemBuilder: (BuildContext _, int index) {
              final _LogMonth month = months[index];
              return SettingsSection(
                label: '${month.label}  ·  ${_countLabel(month.entries.length)}',
                children: <Widget>[
                  for (final SeizureLogDto log in month.entries)
                    SeizureLogRow(log: log, onTap: () => _openAddSheet(existing: log)),
                ],
              );
            },
          );
        }),
      ),
    ],
  );

  void _openAddSheet({SeizureLogDto? existing}) => AddSeizureLogBottomSheet.show(
    onAdd: controller.addEntry,
    onUpdate: controller.updateEntry,
    existingLog: existing,
  );

  static String _countLabel(int count) => count == 1 ? '1 entry' : '$count entries';

  static List<_LogMonth> _groupByMonth(List<SeizureLogDto> logs) {
    final List<_LogMonth> months = <_LogMonth>[];

    for (final SeizureLogDto log in logs) {
      final DateTime at = log.occurredAt;
      final bool sameAsLast =
          months.isNotEmpty && months.last.year == at.year && months.last.month == at.month;

      if (!sameAsLast) {
        months.add(_LogMonth(year: at.year, month: at.month, label: formatLogMonth(at)));
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
