import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seizure_app/core/helpers/app_snackbar.dart';

class MapLauncherService {
  MapLauncherService._();

  static Future<void> openDirections({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final String coordinates = '$latitude,$longitude';

    final List<Uri> candidates = <Uri>[
      if (Platform.isIOS)
        Uri.parse('https://maps.apple.com/?daddr=$coordinates&dirflg=d')
      else
        Uri.parse('google.navigation:q=$coordinates'),
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$coordinates',
      ),
    ];

    for (final Uri uri in candidates) {
      try {
        if (await canLaunchUrl(uri) &&
            await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return;
        }
      } catch (_) {}
    }

    await Clipboard.setData(ClipboardData(text: coordinates));
    showAppSnackbar(
      'Could not open maps',
      '${label == null ? 'Location' : "$label's location"} copied to clipboard: $coordinates',
    );
  }
}
