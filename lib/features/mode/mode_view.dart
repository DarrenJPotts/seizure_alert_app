import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';
import 'package:seizure_app/core/widgets/settings/settings_screen_header.dart';
import 'package:seizure_app/features/mode/view_models/mode_view_model.dart';

class ModeView extends GetView<ModeViewModel> {
  const ModeView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SettingsScreenHeader(
            title: 'Mode',
            backLabel: 'Profile',
            onBack: Get.back,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.twenty,
                Dimensions.twentyTwo,
                Dimensions.twenty,
                Dimensions.twentyFour,
              ),
              children: const <Widget>[_ThisDeviceSection()],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ThisDeviceSection extends GetView<ModeViewModel> {
  const _ThisDeviceSection();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SettingsSection(
        label: 'This device',
        children: <Widget>[
          Obx(
            () => SettingsSwitchRow(
              icon: Icons.shield_outlined,
              title: 'Caregiver mode',
              subtitle: "Watch someone else, don't send SOS",
              value: controller.caregiverMode.value,
              loading: controller.changingCaregiverMode.value,
              onChanged: controller.setCaregiverMode,
            ),
          ),
        ],
      ),
      const SizedBox(height: Dimensions.ten),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.two),
        child: Text(
          'With caregiver mode on, the home tab becomes your watch list and the SOS button is hidden on this device.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 13,
            height: 1.5,
            color: context.secondaryInk,
          ),
        ),
      ),
    ],
  );
}
