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
                description: vm.notificationsBlocked.value
                    ? 'Blocked. Without this you will not hear an alert from your circle.'
                    : 'Receive alerts from your circle and reminders.',
                granted: vm.notificationsGranted.value,
                blocked: vm.notificationsBlocked.value,
                onTap: vm.notificationsGranted.value
                    ? null
                    : vm.requestNotifications,
              )),
          SizedBox(height: Dimensions.sixteen),
          Obx(() => PermissionRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                description: vm.locationBlocked.value
                    ? 'Blocked. Your alerts will be sent without a location.'
                    : 'Share your location with contacts when an alert is sent.',
                granted: vm.locationGranted.value,
                blocked: vm.locationBlocked.value,
                onTap: vm.locationGranted.value ? null : vm.requestLocation,
              )),
          SizedBox(height: Dimensions.twentyFour),
          Text(
            'You can change these later in Profile. The app still works without them — '
            'it just has fewer ways to reach people.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
