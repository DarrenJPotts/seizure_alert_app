import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';

import 'core/controllers/firebase_auth_controller/firebase_auth_controller.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/local_notifications_service.dart';

Future<void> initDependencyInjection() async {
  /// [FirebaseAuthController] used for user Authentication with Firebase
  FirebaseAuthController.instance();

  /// [_setUpNotifications] used to set up notifications services
  await _setUpNotifications();
}

// TODO move to instance method
Future<void> _setUpNotifications() async {
  /// [LocalNotificationsService] used for displaying ocal notifications
  await Get.putAsync(() => LocalNotificationsService().init());

  /// [FirebaseMessagingService] used sending push notifications
  await Get.putAsync(
    () => FirebaseMessagingService().init(localNotificationsService: Get.find<LocalNotificationsService>()),
  );
}
