import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLauncherService {
  MapLauncherService._();

  static Future<void> openDirections({required double latitude, required double longitude, String? label}) async {
    final String coordinates = '$latitude,$longitude';

    final List<Uri> candidates = <Uri>[
      if (Platform.isIOS)
        Uri.parse('https://maps.apple.com/?daddr=$coordinates&dirflg=d')
      else
        Uri.parse('google.navigation:q=$coordinates'),
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$coordinates'),
    ];

    for (final Uri uri in candidates) {
      try {
        if (await canLaunchUrl(uri) && await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {
      }
    }

    await Clipboard.setData(ClipboardData(text: coordinates));
    Get.snackbar(
      '',
      '',
      titleText: const Text(
        'Could not open maps',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      messageText: Text(
        '${label == null ? 'Location' : "$label's location"} copied to clipboard: $coordinates',
        style: const TextStyle(color: Colors.white),
      ),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black,
      margin: EdgeInsets.all(Dimensions.sixteen),
      borderRadius: Dimensions.eight,
      duration: const Duration(seconds: 4),
    );
  }
}
