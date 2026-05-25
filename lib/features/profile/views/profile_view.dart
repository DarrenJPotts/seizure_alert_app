import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/features/profile/view_models/profile_view_model.dart';

import 'widgets/profile_item.dart';
import 'widgets/profile_section.dart';

class ProfileView extends GetView<ProfileViewModel> {
  const ProfileView({super.key});

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    if ([GenericScreenStates.loading, GenericScreenStates.initial].contains(controller.screenState.value)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.screenState.value == GenericScreenStates.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: Dimensions.twelve,
          children: [
            Text(
              controller.errorMessage.value ?? 'Something went wrong',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            TextButton(onPressed: controller.fetchProfile, child: const Text('Retry')),
          ],
        ),
      );
    }

    final UserDto user = controller.user.value!;
    return SingleChildScrollView(
      padding: EdgeInsets.all(Dimensions.twentyFour),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Dimensions.twentyFour,
        children: [
          /// Avatar + name
          Center(
            child: Column(
              spacing: Dimensions.twelve,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.black,
                  child: Text(_initials(user.displayName), style: const TextStyle(color: Colors.white, fontSize: 22)),
                ),
                Text(user.displayName ?? 'No name', style: Theme.of(context).textTheme.titleMedium),
                Text(user.email, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),

          /// Medical ID
          Text('Medical ID', style: Theme.of(context).textTheme.titleMedium),
          ProfileSection(
            items: [
              ProfileItem(icon: Icons.bloodtype_outlined, label: 'Blood Type', value: user.bloodType ?? '—'),
              ProfileItem(icon: Icons.medication_outlined, label: 'Medications', value: user.medications?.first ?? '—'),
              ProfileItem(icon: Icons.warning_amber_outlined, label: 'Seizure Type', value: user.seizureType ?? '—'),
              ProfileItem(icon: Icons.note_outlined, label: 'Emergency Note', value: user.emergencyNote ?? '—'),
            ],
          ),

          /// Settings
          /// Settings
          Text('Settings', style: Theme.of(context).textTheme.titleMedium),
          Obx(() => ProfileSection(
            items: [
              ProfileItem(
                icon: controller.notificationsEnabled.value
                    ? Icons.notifications_outlined
                    : Icons.notifications_off_outlined,
                label: 'Notifications',
                value: controller.notificationsLabel,
                valueColor: controller.notificationsEnabled.value ? null : Colors.red.shade300,
                tappable: true,
                onTap: () => controller.requestNotifications()
              ),
              ProfileItem(
                icon: controller.locationEnabled.value
                    ? Icons.location_on_outlined
                    : Icons.location_off_outlined,
                label: 'Location Sharing',
                value: controller.locationLabel,
                valueColor: controller.locationEnabled.value ? null : Colors.red.shade300,
                tappable: true,
                onTap: () =>controller.requestLocation(),
              ),
              ProfileItem(
                icon: Icons.lock_outline,
                label: 'Privacy',
                value: '',
                tappable: true,
              ),
            ],
          )),
        ],
      ),
    );
  });
}
