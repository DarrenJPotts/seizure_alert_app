import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:latlong2/latlong.dart';

class AlertMapWidget extends StatelessWidget {
  const AlertMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(context.design.cardRadius),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: point,
          initialZoom: 15.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'seizure_app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.ink,
                    border: Border.all(color: context.paper, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SimpleAttributionWidget(
            backgroundColor: context.paper,
            source: Text(
              '© OpenStreetMap contributors',
              style: context.theme.textTheme.labelSmall?.copyWith(
                color: context.secondaryInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AlertMapPlaceholder extends StatelessWidget {
  const AlertMapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: context.designBorder,
        borderRadius: BorderRadius.circular(context.design.cardRadius),
        color: context.ink.withValues(alpha: 0.03),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Icon(
              Icons.location_off_outlined,
              color: context.ink.withValues(alpha: 0.26),
              size: 28,
            ),
            Text(
              'Location unavailable',
              style: context.theme.textTheme.bodySmall?.copyWith(
                color: context.ink.withValues(alpha: 0.38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
