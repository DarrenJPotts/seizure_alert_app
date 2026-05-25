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

  // Android notification channel configuration
  final _androidChannel = const AndroidNotificationChannel(
    'channel_id',
    'Channel name',
    description: 'Android push notification channel',
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

    return this;
  }

  /// Handle notification tap in foreground
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    print('Foreground notification has been tapped: ${response.payload}');
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
      print('Error handling notification navigation: $e');
    }
  }

  /// Show a local notification with the given title, body, and payload.
  Future<void> showNotification(String? title, String? body, String? payload) async {
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
  }

  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    notificationCount.value = 0;
  }

  @override
  void onClose() {
    // Cleanup if needed
    print('LocalNotificationsService closing');
    super.onClose();
  }
}
