import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/widgets/alert_map_widget.dart';
import 'package:seizure_app/features/caregiver/view_models/incoming_alert_view_model.dart';

class IncomingAlertView extends GetView<IncomingAlertViewModel> {
  const IncomingAlertView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          final state = controller.screenState.value;

          if (state == GenericScreenStates.loading ||
              state == GenericScreenStates.initial) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (state == GenericScreenStates.error || controller.detail.value == null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(Dimensions.twentyFour),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: Dimensions.twelve,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.white38),
                    Text(
                      'This alert is no longer available',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final detail = controller.detail.value!;
          final owner = detail.ownerProfile;
          final distance = controller.distanceLabel();

          return Padding(
            padding: EdgeInsets.fromLTRB(
              Dimensions.twentyFour,
              Dimensions.sixteen,
              Dimensions.twentyFour,
              Dimensions.twentyFour,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  padding: EdgeInsets.zero,
                ),
                SizedBox(height: Dimensions.eight),
                Text(
                  'SOS · ${controller.elapsedLabel().toUpperCase()}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                ),
                SizedBox(height: Dimensions.eight),
                Text(
                  '${owner.displayName} needs help',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (distance != null) ...[
                  SizedBox(height: Dimensions.four),
                  Text(
                    distance,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white54),
                  ),
                ],
                SizedBox(height: Dimensions.twenty),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 160,
                          width: double.infinity,
                          child: detail.alert.latitude != null &&
                                  detail.alert.longitude != null
                              ? AlertMapWidget(
                                  latitude: detail.alert.latitude!,
                                  longitude: detail.alert.longitude!,
                                )
                              : const _DarkMapPlaceholder(),
                        ),
                        SizedBox(height: Dimensions.twentyFour),
                        if (owner.bloodType != null || owner.seizureType != null) ...[
                          Text(
                            'MEDICAL ID',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white38,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                ),
                          ),
                          SizedBox(height: Dimensions.twelve),
                          Row(
                            children: [
                              if (owner.bloodType != null)
                                Expanded(
                                  child: _MedicalIdCard(
                                    label: 'Blood type',
                                    value: owner.bloodType!,
                                  ),
                                ),
                              if (owner.bloodType != null && owner.seizureType != null)
                                SizedBox(width: Dimensions.twelve),
                              if (owner.seizureType != null)
                                Expanded(
                                  child: _MedicalIdCard(
                                    label: 'Seizure type',
                                    value: owner.seizureType!,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: Dimensions.twentyFour),
                        ],
                        if (owner.emergencyNote != null && owner.emergencyNote!.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(Dimensions.sixteen),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EMERGENCY NOTE',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Colors.white38,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 2,
                                      ),
                                ),
                                SizedBox(height: Dimensions.eight),
                                Text(
                                  owner.emergencyNote!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: Dimensions.eight),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: Dimensions.sixteen),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isResponding.value ? null : controller.respond,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white38,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: Dimensions.sixteen),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("I'm responding"),
                  ),
                ),
                if (owner.phone != null) ...[
                  SizedBox(height: Dimensions.twelve),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: controller.callOwner,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: EdgeInsets.symmetric(vertical: Dimensions.sixteen),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Call ${owner.displayName}'),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _MedicalIdCard extends StatelessWidget {
  const _MedicalIdCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Dimensions.sixteen),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white54),
          ),
          SizedBox(height: Dimensions.four),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _DarkMapPlaceholder extends StatelessWidget {
  const _DarkMapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.03),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            const Icon(Icons.location_off_outlined, color: Colors.white38, size: 28),
            Text(
              'Location unavailable',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}
