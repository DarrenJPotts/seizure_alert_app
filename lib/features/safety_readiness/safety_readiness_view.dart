import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/wearable_device_dto.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/services/wearable_service.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';
import 'package:seizure_app/core/widgets/settings/settings_screen_header.dart';
import 'package:seizure_app/features/safety_readiness/view_models/safety_readiness_view_model.dart';
import 'package:seizure_app/features/root/root_view.dart';

class SafetyReadinessView extends GetView<SafetyReadinessViewModel> {
  const SafetyReadinessView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SettingsScreenHeader(
            title: 'Safety readiness',
            backLabel: 'Profile',
            onBack: Get.back,
            trailing: Obx(
              () => IconButton(
                tooltip: 'Refresh readiness',
                onPressed: controller.loading.value
                    ? null
                    : controller.refreshReadiness,
                icon: controller.loading.value
                    ? SizedBox.square(
                        dimension: Dimensions.eighteen,
                        child: const CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.refresh),
              ),
            ),
          ),
          Expanded(
            child: Obx(
              () => ListView(
                padding: EdgeInsets.fromLTRB(
                  Dimensions.twentyFour,
                  Dimensions.twentyFour,
                  Dimensions.twentyFour,
                  Dimensions.twentyFour,
                ),
                children: <Widget>[
                  _OverallStatus(controller: controller),
                  SizedBox(height: Dimensions.twentyFour),
                  _PhoneSection(controller: controller),
                  SizedBox(height: Dimensions.twentyFour),
                  _CaregiverSection(controller: controller),
                  SizedBox(height: Dimensions.twentyFour),
                  _WearableSection(controller: controller),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OverallStatus extends StatelessWidget {
  const _OverallStatus({required this.controller});

  final SafetyReadinessViewModel controller;

  @override
  Widget build(BuildContext context) {
    final bool ready =
        controller.networkAvailable.value &&
        controller.notificationsReady &&
        controller.locationReady.value &&
        controller.readyCaregiverCount > 0;
    return Container(
      padding: EdgeInsets.all(Dimensions.twenty),
      decoration: BoxDecoration(
        color: ready ? Colors.black : Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(Dimensions.sixteen),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            ready ? Icons.check_circle_outline : Icons.warning_amber_outlined,
            color: ready ? Colors.white : Colors.black,
          ),
          SizedBox(width: Dimensions.twelve),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  ready ? 'Core alerts are ready' : 'Setup needs attention',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ready ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: Dimensions.four),
                Text(
                  ready
                      ? 'This phone can send an alert to at least one connected caregiver.'
                      : 'Review the checks below before relying on alerts.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ready ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneSection extends StatelessWidget {
  const _PhoneSection({required this.controller});

  final SafetyReadinessViewModel controller;

  @override
  Widget build(BuildContext context) => SettingsSection(
    label: 'This phone',
    children: <Widget>[
      _ReadinessRow(
        icon: Icons.wifi_outlined,
        title: 'Connection',
        ready: controller.networkAvailable.value,
        value: controller.networkAvailable.value ? 'Available' : 'Offline',
      ),
      _ReadinessRow(
        icon: Icons.notifications_outlined,
        title: 'Push notifications',
        ready: controller.notificationsReady,
        value: controller.notificationsReady ? 'Ready' : 'Needs attention',
      ),
      _ReadinessRow(
        icon: Icons.location_on_outlined,
        title: 'Alert location',
        ready: controller.locationReady.value,
        value: controller.locationReady.value ? 'Available' : 'Not available',
      ),
    ],
  );
}

class _CaregiverSection extends StatelessWidget {
  const _CaregiverSection({required this.controller});

  final SafetyReadinessViewModel controller;

  @override
  Widget build(BuildContext context) => SettingsSection(
    label: 'Caregiver delivery',
    children: <Widget>[
      _ReadinessRow(
        icon: Icons.people_outline,
        title: 'Connected caregivers',
        ready: controller.readyCaregiverCount > 0,
        value: '${controller.readyCaregiverCount} ready',
      ),
      _ReadinessRow(
        icon: Icons.notification_important_outlined,
        title: 'Last delivery test',
        ready:
            controller.readyCaregiverCount > 0 &&
            controller.testedCaregiverCount == controller.readyCaregiverCount,
        value: _testLabel(controller),
      ),
      SettingsNavRow(
        icon: Icons.contacts_outlined,
        title: 'Manage caregivers',
        onTap: () {
          Get.back<void>();
          if (Get.isRegistered<RootViewModel>()) {
            Get.find<RootViewModel>().changePage(3);
          } else {
            Get.offAllNamed(AppRoutes.root);
          }
        },
      ),
    ],
  );

  String _testLabel(SafetyReadinessViewModel controller) {
    final DateTime? testedAt = controller.lastCaregiverTest;
    if (testedAt == null) return 'Not tested';
    final int days = DateTime.now().difference(testedAt).inDays;
    final String when = days == 0 ? 'Today' : '$days days ago';
    return '${controller.testedCaregiverCount}/${controller.readyCaregiverCount} reached · $when';
  }
}

class _WearableSection extends StatelessWidget {
  const _WearableSection({required this.controller});

  final SafetyReadinessViewModel controller;

  @override
  Widget build(BuildContext context) => SettingsSection(
    label: 'Wearables',
    children: <Widget>[
      if (controller.devices.isEmpty)
        const SettingsMessageRow(
          'No wearable paired. A paired Garmin can send a manual SOS and show your current safety state.',
        )
      else
        for (final WearableDeviceDto device in controller.devices)
          SettingsTileRow(
            leading: const Icon(Icons.watch_outlined),
            title: device.name,
            subtitle: _deviceStatus(device),
            trailing: controller.removingDeviceId.value == device.id
                ? SizedBox.square(
                    dimension: Dimensions.eighteen,
                    child: const CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 1.5,
                    ),
                  )
                : const Icon(Icons.delete_outline, color: Colors.black54),
            onTap: controller.removingDeviceId.value == null
                ? () => _removeDevice(context, device)
                : null,
          ),
      SettingsActionRow(
        title: 'Pair a Garmin watch',
        onTap: controller.creatingPairingCode.value
            ? () {}
            : () => _showPairingCode(context),
      ),
    ],
  );

  String _deviceStatus(WearableDeviceDto device) {
    final String battery = device.batteryPercent == null
        ? 'Battery unavailable'
        : '${device.batteryPercent}% battery';
    return device.recentlySeen
        ? 'Connected · $battery'
        : 'Not recently seen · $battery';
  }

  Future<void> _showPairingCode(BuildContext context) async {
    HapticFeedback.selectionClick();
    final result = await controller.createPairingCode();
    if (!context.mounted) return;
    if (!result.isSuccess || result.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not create a code.')),
      );
      return;
    }
    final WearablePairingCode pairing = result.data!;
    await AppBottomSheet.show(
      context: context,
      builder: (BuildContext sheetContext) => AppBottomSheetContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Pair Garmin watch',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: Dimensions.twelve),
            const Text(
              'Open Seizure Alert on the watch and enter this six-digit code.',
            ),
            SizedBox(height: Dimensions.twentyFour),
            Semantics(
              label: 'Pairing code ${pairing.code.split('').join(' ')}',
              child: SelectableText(
                pairing.code,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: Dimensions.eight,
                ),
              ),
            ),
            SizedBox(height: Dimensions.twelve),
            Text(
              'Expires at ${TimeOfDay.fromDateTime(pairing.expiresAt).format(context)}.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            SizedBox(height: Dimensions.twentyFour),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: Get.back<void>,
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeDevice(
    BuildContext context,
    WearableDeviceDto device,
  ) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Remove this wearable?'),
            content: Text(
              '${device.name} will no longer be able to send alerts.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    final String? error = await controller.removeDevice(device.id);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.ready,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool ready;

  @override
  Widget build(BuildContext context) => SettingsValueRow(
    icon: icon,
    label: title,
    value: value,
    valueColor: ready ? Colors.black54 : Colors.black,
  );
}
