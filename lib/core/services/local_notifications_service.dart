import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class LocalNotificationsService extends GetxService {

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

final _androidInitializationSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');

final _iosInitializationSettings = const DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
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
  final _androidChannel = const AndroidNotificationChannel(
    alertChannelId,
    'Emergency alerts',
    description:
        'SOS alerts, Heads Up check-ins, and missed check-ins from your circle.',
    importance: Importance.max,
  );

bool _isFlutterLocalNotificationInitialized = false;

int _notificationIdCounter = 0;

final notificationCount = 0.obs;
  final lastNotificationPayload = Rxn<String>();

Future<LocalNotificationsService> init() async {
    if (_isFlutterLocalNotificationInitialized) {
      return this;
    }

    try {

      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final initializationSettings = InitializationSettings(
        android: _androidInitializationSettings,
        iOS: _iosInitializationSettings,
      );

await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

_isFlutterLocalNotificationInitialized = true;
    } catch (e) {
      debugPrint('[LocalNotificationsService] Error initializing: $e');
    }

    return this;
  }

void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('[LocalNotificationsService] Foreground notification tapped: ${response.payload}');
    lastNotificationPayload.value = response.payload;

_handleNotificationNavigation(response.payload);
  }

void _handleNotificationNavigation(String? payload) {
    if (payload == null || payload.isEmpty) return;

try {

      if (payload.startsWith('/')) {
        Get.toNamed(payload);
      }

    } catch (e) {
      debugPrint('[LocalNotificationsService] Error handling notification navigation: $e');
    }
  }

Future<void> showNotification(String? title, String? body, String? payload) async {
    try {

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.max,
        priority: Priority.high,
      );

const iosDetails = DarwinNotificationDetails();

final notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

await _flutterLocalNotificationsPlugin.show(
        id: _notificationIdCounter++,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );

notificationCount.value++;
    } catch (e) {
      debugPrint('[LocalNotificationsService] Error showing notification: $e');
    }
  }

Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('[LocalNotificationsService] Error cancelling notification: $e');
    }
  }

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
