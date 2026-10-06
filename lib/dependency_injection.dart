import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';

import 'core/controllers/firebase_auth_controller/firebase_auth_controller.dart';
import 'core/controllers/theme_controller/theme_controller.dart';
import 'core/services/app_mode_service.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/local_notifications_service.dart';

Future<void> initDependencyInjection() async {

  FirebaseAuthController.instance();

final SharedPreferences prefs = await SharedPreferences.getInstance();

  await Get.putAsync(() async => AppModeService(prefs).init());

await Get.putAsync(() async => ThemeController(prefs).init());

  /// Notification setup failures must not block app launch — SOS and Heads
  /// Up are usable without push notifications working.
  await _setUpNotifications();
}

Future<void> _setUpNotifications() async {
  try {

    await Get.putAsync(() => LocalNotificationsService().init());

await Get.putAsync(
      () => FirebaseMessagingService().init(localNotificationsService: Get.find<LocalNotificationsService>()),
    );
  } catch (e) {
    debugPrint('[DependencyInjection] Error setting up notifications: $e');
  }
}
