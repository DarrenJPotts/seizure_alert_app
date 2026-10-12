import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/medication_reminder_dto.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';
import 'package:seizure_app/core/widgets/settings/settings_screen_header.dart';
import 'package:seizure_app/features/safety_plan/view_models/safety_plan_view_model.dart';

class SafetyPlanView extends GetView<SafetyPlanViewModel> {
  const SafetyPlanView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
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
                return const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                );
              }
              if (controller.error.value != null) {
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
                padding: EdgeInsets.fromLTRB(
                  Dimensions.twentyFour,
                  Dimensions.twentyFour,
                  Dimensions.twentyFour,
                  Dimensions.twentyFour,
                ),
                children: <Widget>[
                  _ActionPlanSection(controller: controller),
                  SizedBox(height: Dimensions.twentyFour),
                  _MedicationSection(controller: controller),
                  SizedBox(height: Dimensions.twentyFour),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.saving.value
                          ? null
                          : () => _save(context),
                      child: controller.saving.value
                          ? SizedBox.square(
                              dimension: Dimensions.twenty,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
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
              ? 'Safety plan and reminders saved.'
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
        padding: EdgeInsets.all(Dimensions.sixteen),
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
            SizedBox(height: Dimensions.twelve),
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
          label: 'Call emergency services after',
          value: '${controller.callEmergencyAfterMinutes.value} minutes',
          onTap: () => _chooseEmergencyTime(context),
        ),
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
  Widget build(BuildContext context) => Obx(
    () => SettingsSection(
      label: 'Medication reminders',
      children: <Widget>[
        if (controller.reminders.isEmpty)
          const SettingsMessageRow(
            'No reminders added. Reminders are scheduled on this device.',
          )
        else
          for (final MedicationReminderDto reminder in controller.reminders)
            SettingsSwitchRow(
              icon: Icons.medication_outlined,
              title: reminder.name,
              subtitle: <String>[
                if (reminder.dose?.trim().isNotEmpty == true)
                  reminder.dose!.trim(),
                _formatTime(reminder.hour, reminder.minute),
              ].join(' · '),
              value: reminder.enabled,
              onChanged: (bool enabled) =>
                  controller.setReminderEnabled(reminder.id, enabled),
            ),
        SettingsActionRow(
          title: 'Add medication reminder',
          onTap: () => _addReminder(context),
        ),
        if (controller.reminders.isNotEmpty)
          for (final MedicationReminderDto reminder in controller.reminders)
            SettingsTileRow(
              title: 'Remove ${reminder.name}',
              subtitle: 'Stops this reminder on this device',
              trailing: const Icon(Icons.delete_outline, color: Colors.black54),
              onTap: () => controller.removeReminder(reminder.id),
            ),
      ],
    ),
  );

  Future<void> _addReminder(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController doseController = TextEditingController();
    final Rx<TimeOfDay> time = const TimeOfDay(hour: 8, minute: 0).obs;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool? add = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Medication reminder'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: nameController,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Medication'),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty
                    ? 'Enter a medication name'
                    : null,
              ),
              SizedBox(height: Dimensions.twelve),
              TextFormField(
                controller: doseController,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Dose (optional)'),
              ),
              SizedBox(height: Dimensions.twelve),
              Obx(
                () => OutlinedButton.icon(
                  onPressed: () async {
                    final TimeOfDay? chosen = await showTimePicker(
                      context: dialogContext,
                      initialTime: time.value,
                    );
                    if (chosen != null) time.value = chosen;
                  },
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(time.value.format(dialogContext)),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (add == true) {
      controller.addReminder(
        MedicationReminderDto(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: nameController.text.trim(),
          dose: doseController.text.trim().isEmpty
              ? null
              : doseController.text.trim(),
          hour: time.value.hour,
          minute: time.value.minute,
        ),
      );
    }
    nameController.dispose();
    doseController.dispose();
  }

  static String _formatTime(int hour, int minute) {
    final int displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';
  }
}
