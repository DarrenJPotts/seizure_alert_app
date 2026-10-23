import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/services/network_status_service.dart';

class OfflineBanner extends GetView<NetworkStatusService> {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    if (controller.hasNetwork.value) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: context.heroSurface,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.twentyFour,
        vertical: Dimensions.twelve,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, color: context.heroInk, size: 20),
          const SizedBox(width: Dimensions.twelve),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Dimensions.four,
              children: [
                Text(
                  'No network connection',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.heroInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'SOS and Heads Up updates may be queued until you reconnect.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.heroInk.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  });
}
