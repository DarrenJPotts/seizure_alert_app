import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/features/seizure_log/view_models/seizure_log_view_model.dart';
import 'package:seizure_app/features/seizure_log/widgets/add_seizure_log_bottom_sheet.dart';
import 'package:seizure_app/features/seizure_log/widgets/seizure_log_card.dart';

class SeizureLogView extends GetView<SeizureLogViewModel> {
  const SeizureLogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.twentyFour,
            Dimensions.twentyFour,
            Dimensions.twentyFour,
            Dimensions.twelve,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Seizure Log',
                  style: context.theme.textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => AddSeizureLogBottomSheet.show(
                  onAdd: controller.addEntry,
                  onUpdate: controller.updateEntry,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add entry'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
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
                      'Could not load seizure log',
                      style: context.theme
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              );
            }

            final logs = controller.logs;

            if (logs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: Dimensions.twelve,
                  children: [
                    const Icon(Icons.bolt_outlined,
                        size: 48, color: Colors.black26),
                    Text(
                      'No seizures logged yet',
                      style: context.theme
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: () => AddSeizureLogBottomSheet.show(
                        onAdd: controller.addEntry,
                        onUpdate: controller.updateEntry,
                      ),
                      child: const Text('Add your first entry'),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.twentyFour,
                vertical: Dimensions.four,
              ),
              itemCount: logs.length,
              separatorBuilder: (_, _) => SizedBox(height: Dimensions.twelve),
              itemBuilder: (context, index) => SeizureLogCard(
                log: logs[index],
                onTap: () => AddSeizureLogBottomSheet.show(
                  onAdd: controller.addEntry,
                  onUpdate: controller.updateEntry,
                  existingLog: logs[index],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
