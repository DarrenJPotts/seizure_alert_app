import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class LocalNotificationsService extends GetxService {
  // Main plugin instance for handling notifications
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  // Android-specific initialization settings using app launcher icon
  final _androidInitializationSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS-specific initialization settings with permission requests
  final _iosInitializationSettings = const DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  /// Android notification channel for alerts.
  ///
  /// The id is duplicated in `AndroidManifest.xml` as FCM's
  /// `default_notification_channel_id`. Without that meta-data, notifications
  /// that arrive while the app is backgrounded are posted by the system to a
  /// default channel instead of this one, and lose their max importance —
  /// which for an app whose whole purpose is waking someone up is the
  /// difference between working and not. Keep the two values in sync.
  static const String alertChannelId = 'seizure_alerts';

  // The name and description are what the user sees in Android's notification
  // settings, so they read as plain language rather than developer labels.
  final _androidChannel = const AndroidNotificationChannel(
    alertChannelId,
    'Emergency alerts',
    description:
        'SOS alerts, Heads Up check-ins, and missed check-ins from your circle.',
    importance: Importance.max,
  );

  // Flag to track initialization status
  bool _isFlutterLocalNotificationInitialized = false;

  // Counter for generating unique notification IDs
  int _notificationIdCounter = 0;

  // Reactive variables (optional - if you want to track notification state)
  final notificationCount = 0.obs;
  final lastNotificationPayload = Rxn<String>();

  /// Initializes the local notifications plugin for Android and iOS.
  Future<LocalNotificationsService> init() async {
    // Check if already initialized to prevent redundant setup
    if (_isFlutterLocalNotificationInitialized) {
      return this;
    }

    try {
      // Create plugin instance
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // Combine platform-specific settings
      final initializationSettings = InitializationSettings(
        android: _androidInitializationSettings,
        iOS: _iosInitializationSettings,
      );

      // Initialize plugin with settings and callback for notification taps
      await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      // Create Android notification channel
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      // Mark initialization as complete
      _isFlutterLocalNotificationInitialized = true;
    } catch (e) {
      debugPrint('[LocalNotificationsService] Error initializing: $e');
    }

    return this;
  }

  /// Handle notification tap in foreground
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('[LocalNotificationsService] Foreground notification tapped: ${response.payload}');
    lastNotificationPayload.value = response.payload;

    // Handle navigation with GetX
    _handleNotificationNavigation(response.payload);
  }

  /// Handle navigation based on notification payload
  void _handleNotificationNavigation(String? payload) {
    if (payload == null || payload.isEmpty) return;

    // Example: Parse payload and navigate
    try {
      // If payload is a route
      if (payload.startsWith('/')) {
        Get.toNamed(payload);
      }
      // Add more navigation logic as needed
    } catch (e) {
      debugPrint('[LocalNotificationsService] Error handling notification navigation: $e');
    }
  }

  /// Show a local notification with the given title, body, and payload.
  Future<void> showNotification(String? title, String? body, String? payload) async {
    try {
      // Android-specific notification details
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.max,
        priority: Priority.high,
      );

      // iOS-specific notification details
      const iosDetails = DarwinNotificationDetails();

      // Combine platform-specific details
      final notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // Display the notification
      await _flutterLocalNotificationsPlugin.show(
        id: _notificationIdCounter++,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );

      // Update reactive counter
      notificationCount.value++;
    } catch (e) {
      debugPrint('[LocalNotificationsService] Error showing notification: $e');
    }
  }

  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('[LocalNotificationsService] Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      notificationCount.value = 0;
    } catch (e) {
      debugPrint('[LocalNotificationsService] Error cancelling all notifications: $e');
    }
  }

  @override
  void onClose() {
    debugPrint('[LocalNotificationsService] closing');
    super.onClose();
  }
}
