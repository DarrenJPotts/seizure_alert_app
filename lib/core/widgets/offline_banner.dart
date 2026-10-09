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
          color: Colors.black,
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.twentyFour,
            vertical: Dimensions.twelve,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cloud_off_outlined, color: Colors.white, size: 20),
              SizedBox(width: Dimensions.twelve),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Dimensions.four,
                  children: [
                    Text(
                      'No network connection',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'SOS and Heads Up updates may be queued until you reconnect.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
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
