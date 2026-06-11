import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:seizure_app/features/onboarding/widgets/permission_row.dart';

class OnboardingStepPermissions extends StatelessWidget {
  const OnboardingStepPermissions({super.key, required this.vm});

  final OnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(Dimensions.twentyFour),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: Dimensions.twentyFour),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Dimensions.eight,
            children: [
              Text('Stay protected',
                  style: Theme.of(context).textTheme.titleMedium),
              Text(
                'Enable these so your circle can be reached and your location shared when it matters most.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black54),
              ),
            ],
          ),
          SizedBox(height: Dimensions.thirtyTwo),
          Obx(() => PermissionRow(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                description: 'Receive alerts from your circle and reminders.',
                granted: vm.notificationsGranted.value,
                onTap: vm.notificationsGranted.value
                    ? null
                    : vm.requestNotifications,
              )),
          SizedBox(height: Dimensions.sixteen),
          Obx(() => PermissionRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                description:
                    'Share your location with contacts when an alert is sent.',
                granted: vm.locationGranted.value,
                onTap: vm.locationGranted.value ? null : vm.requestLocation,
              )),
        ],
      ),
    );
  }
}
