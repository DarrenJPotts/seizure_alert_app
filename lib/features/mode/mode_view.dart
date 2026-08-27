import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/watched_person_dto.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';
import 'package:seizure_app/core/widgets/settings/settings_screen_header.dart';
import 'package:seizure_app/features/caregiver/widgets/caregiver_avatar.dart';
import 'package:seizure_app/features/mode/view_models/mode_view_model.dart';

class ModeView extends GetView<ModeViewModel> {
  const ModeView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F1F1),
    body: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SettingsScreenHeader(title: 'Mode', backLabel: 'Profile', onBack: Get.back),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                Dimensions.twenty,
                Dimensions.twentyTwo,
                Dimensions.twenty,
                Dimensions.twentyFour,
              ),
              children: <Widget>[
                const _ThisDeviceSection(),
                SizedBox(height: Dimensions.twentySix),
                const _WatchingSection(),
              ],
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
              onChanged: controller.setCaregiverMode,
            ),
          ),
          SettingsNavRow(
            icon: Icons.notifications_active_outlined,
            title: 'Alert override',
            trailingText: 'Ignore silent',
            onTap: controller.openAlertOverride,
          ),
          Obx(
            () => SettingsSwitchRow(
              icon: Icons.call_outlined,
              title: 'Auto-answer calls',
              value: controller.autoAnswerCalls.value,
              onChanged: controller.setAutoAnswerCalls,
            ),
          ),
        ],
      ),
      SizedBox(height: Dimensions.ten),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: Dimensions.two),
        child: Text(
          'With caregiver mode on, the home tab becomes your watch list and the SOS button is hidden on this device.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 13,
            height: 1.5,
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
      ),
    ],
  );
}

class _WatchingSection extends GetView<ModeViewModel> {
  const _WatchingSection();

  @override
  Widget build(BuildContext context) => Obx(
    () => SettingsSection(
      label: 'Watching',
      children: <Widget>[
        if (controller.loadingWatching.value)
          const SettingsMessageRow('Loading…')
        else if (controller.watching.isEmpty)
          const SettingsMessageRow('You are not watching anyone yet')
        else
          for (final WatchedPersonDto person in controller.watching)
            SettingsTileRow(
              leading: CaregiverAvatar(name: person.ownerName, size: 34),
              title: person.ownerName,
              subtitle: _accessLabel(person),
            ),
        SettingsActionRow(
          title: 'Accept an invite',
          badgeCount: controller.pendingInvites.length,
          onTap: controller.openInvite,
        ),
      ],
    ),
  );

  String _accessLabel(WatchedPersonDto person) => switch (person.status) {
    WatchedPersonStatus.sos => 'SOS active now',
    WatchedPersonStatus.headsUp => 'Heads Up active',
    WatchedPersonStatus.monitoring => 'Receiving alerts',
  };
}
