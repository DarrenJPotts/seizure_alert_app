import 'package:flutter/foundation.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';

import 'core/controllers/firebase_auth_controller/firebase_auth_controller.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/local_notifications_service.dart';

Future<void> initDependencyInjection() async {
  /// [FirebaseAuthController] used for user Authentication with Firebase
  FirebaseAuthController.instance();

  /// Notification setup failures must not block app launch — SOS and Heads
  /// Up are usable without push notifications working.
  await _setUpNotifications();
}

Future<void> _setUpNotifications() async {
  try {
    /// [LocalNotificationsService] used for displaying local notifications
    await Get.putAsync(() => LocalNotificationsService().init());

    /// [FirebaseMessagingService] used sending push notifications
    await Get.putAsync(
      () => FirebaseMessagingService().init(localNotificationsService: Get.find<LocalNotificationsService>()),
    );
  } catch (e) {
    debugPrint('[DependencyInjection] Error setting up notifications: $e');
  }
}
