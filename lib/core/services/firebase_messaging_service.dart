import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'firebase_collections_service.dart';
import 'local_notifications_service.dart';

class FirebaseMessagingService extends GetxService {
  // Reference to local notifications service
  LocalNotificationsService? _localNotificationsService;

  // Reactive FCM token
  final fcmToken = Rxn<String>();

  // Reactive notification data
  final lastNotification = Rxn<RemoteMessage>();

  /// Initialize Firebase Messaging
  Future<FirebaseMessagingService> init({
    required LocalNotificationsService localNotificationsService,
  }) async {
    _localNotificationsService = localNotificationsService;

    await _handlePushNotificationsToken();
    await _requestPermission();

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Background/terminated tap handling
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Check initial message
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedApp(initialMessage);
    }

    return this;
  }

  Future<void> _handlePushNotificationsToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      fcmToken.value = token;
      await _persistToken(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      fcmToken.value = newToken;
      _persistToken(newToken);
    });
  }

  Future<void> _persistToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    await FirestoreService.instance().updateFcmToken(uid, token);
  }

  Future<void> _requestPermission() async {
    final result = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${result.authorizationStatus}');
  }

  void _onForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.data.toString()}');
    lastNotification.value = message;

    final notificationData = message.notification;
    if (notificationData != null) {
      _localNotificationsService?.showNotification(
        notificationData.title,
        notificationData.body,
        message.data.toString(),
      );
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    print('Notification caused app to open: ${message.data.toString()}');
    lastNotification.value = message;

    // Navigation with GetX
    _handleNotificationNavigation(message);
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    // Example: Navigate based on notification data
    final data = message.data;

    if (data.containsKey('route')) {
      Get.toNamed(data['route']);
    } else if (data.containsKey('screen')) {
      switch (data['screen']) {
        case 'home':
          Get.offAllNamed('/home');
          break;
        case 'profile':
          Get.toNamed('/profile');
          break;
      // Add more cases as needed
      }
    }
  }
}

// Background handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.data.toString()}');
}