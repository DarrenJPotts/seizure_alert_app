import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';
import 'package:seizure_app/core/widgets/settings/settings_screen_header.dart';
import 'package:seizure_app/features/safety_plan/view_models/safety_plan_view_model.dart';

class SafetyPlanView extends GetView<SafetyPlanViewModel> {
  const SafetyPlanView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.paper,
    body: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SettingsScreenHeader(
            title: 'Safety plan',
            backLabel: 'Profile',
            onBack: Get.back,
          ),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return Center(
                  child: CircularProgressIndicator(color: context.ink),
                );
              }
              if (controller.error.value != null && !controller.hasLoadedPlan) {
                return SettingsScreenPlaceholder(
                  icon: Icons.error_outline,
                  message: controller.error.value!,
                  action: TextButton(
                    onPressed: controller.load,
                    child: const Text('Retry'),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.twentyFour,
                  Dimensions.twentyFour,
                  Dimensions.twentyFour,
                  Dimensions.twentyFour,
                ),
                children: <Widget>[
                  if (controller.error.value != null) ...[
                    SettingsMessageRow(controller.error.value!),
                    const SizedBox(height: Dimensions.twelve),
                  ],
                  _ActionPlanSection(controller: controller),
                  const SizedBox(height: Dimensions.twentyFour),
                  _MedicationSection(controller: controller),
                  const SizedBox(height: Dimensions.twentyFour),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.saving.value
                          ? null
                          : () => _save(context),
                      child: controller.saving.value
                          ? SizedBox.square(
                              dimension: Dimensions.twenty,
                              child: CircularProgressIndicator(
                                color: context.paper,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save safety plan'),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    ),
  );

  Future<void> _save(BuildContext context) async {
    HapticFeedback.selectionClick();
    final bool saved = await controller.save();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Safety plan saved.'
              : controller.error.value ?? 'Could not save your safety plan.',
        ),
      ),
    );
  }
}

class _ActionPlanSection extends StatelessWidget {
  const _ActionPlanSection({required this.controller});

  final SafetyPlanViewModel controller;

  @override
  Widget build(BuildContext context) => SettingsSection(
    label: 'Seizure action plan',
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.all(Dimensions.sixteen),
        child: Column(
          children: <Widget>[
            TextField(
              controller: controller.actionPlanController,
              minLines: 4,
              maxLines: 7,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Instructions for a caregiver',
                hintText:
                    'Describe what to do, what to avoid, and when to call emergency services.',
              ),
            ),
            const SizedBox(height: Dimensions.twelve),
            TextField(
              controller: controller.rescueMedicationController,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Rescue medication',
                hintText: 'Name, dose, and when it may be given',
              ),
            ),
          ],
        ),
      ),
      Obx(
        () => SettingsValueRow(
          icon: Icons.emergency_outlined,
          label: 'Emergency call guidance',
          value: 'After ${controller.callEmergencyAfterMinutes.value} minutes',
          onTap: () => _chooseEmergencyTime(context),
        ),
      ),
      const SettingsMessageRow(
        'This is guidance for caregivers. The app does not call emergency services automatically.',
      ),
      Obx(
        () => SettingsSwitchRow(
          icon: Icons.volume_up_outlined,
          title: 'Nearby audible alert',
          subtitle: 'Sound a local alert when SOS starts',
          value: controller.nearbyAudibleAlert.value,
          onChanged: (bool value) =>
              controller.nearbyAudibleAlert.value = value,
        ),
      ),
    ],
  );

  Future<void> _chooseEmergencyTime(BuildContext context) async {
    final int? value = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) => SimpleDialog(
        title: const Text('Call emergency services after'),
        children: <Widget>[
          for (final int minutes in <int>[3, 5, 10, 15])
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(minutes),
              child: Text('$minutes minutes'),
            ),
        ],
      ),
    );
    if (value != null) controller.callEmergencyAfterMinutes.value = value;
  }
}

class _MedicationSection extends StatelessWidget {
  const _MedicationSection({required this.controller});
  final SafetyPlanViewModel controller;
  @override
  Widget build(BuildContext context) => SettingsSection(
    label: 'Reminders',
    children: [
      SettingsNavRow(
        icon: Icons.notifications_active_outlined,
        title: 'Manage reminders',
        onTap: () => Get.toNamed(AppRoutes.reminders),
      ),
    ],
  );
}
