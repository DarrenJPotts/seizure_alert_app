import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/medication_reminder_dto.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationsService extends GetxService {
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  final _androidInitializationSettings = const AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

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
  static const String medicationChannelId = 'medication_reminders';
  static const int nearbyEmergencyNotificationId = 900001;
  final _androidChannel = const AndroidNotificationChannel(
    alertChannelId,
    'Emergency alerts',
    description:
        'SOS alerts, Heads Up check-ins, and missed check-ins from your circle.',
    importance: Importance.max,
  );
  final _medicationChannel = const AndroidNotificationChannel(
    medicationChannelId,
    'Medication reminders',
    description: 'Daily reminders for medication recorded in your care plan.',
    importance: Importance.high,
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
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_medicationChannel);

      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Africa/Johannesburg'));

      _isFlutterLocalNotificationInitialized = true;
    } catch (e) {
      debugPrint('[LocalNotificationsService] Error initializing: $e');
    }

    return this;
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint(
      '[LocalNotificationsService] Foreground notification tapped: ${response.payload}',
    );
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
      debugPrint(
        '[LocalNotificationsService] Error handling notification navigation: $e',
      );
    }
  }

  Future<void> showNotification(
    String? title,
    String? body,
    String? payload,
  ) async {
    try {
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.max,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

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
      debugPrint(
        '[LocalNotificationsService] Error cancelling notification: $e',
      );
    }
  }

  Future<void> showNearbyEmergencyAlert(String instructions) async {
    if (!_isFlutterLocalNotificationInitialized) return;
    try {
      await _flutterLocalNotificationsPlugin.show(
        id: nearbyEmergencyNotificationId,
        title: 'Emergency assistance needed',
        body: instructions.trim().isEmpty
            ? 'A person nearby may be having a seizure.'
            : instructions.trim(),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            alertChannelId,
            'Emergency alerts',
            channelDescription:
                'SOS alerts, Heads Up check-ins, and missed check-ins from your circle.',
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            ongoing: true,
            autoCancel: false,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        payload: '/',
      );
    } catch (error) {
      debugPrint(
        '[LocalNotificationsService] Error showing nearby alert: $error',
      );
    }
  }

  Future<void> cancelNearbyEmergencyAlert() =>
      cancelNotification(nearbyEmergencyNotificationId);

  Future<void> replaceMedicationReminders({
    required List<MedicationReminderDto> previous,
    required List<MedicationReminderDto> current,
  }) async {
    if (!_isFlutterLocalNotificationInitialized) return;
    for (final MedicationReminderDto reminder in <MedicationReminderDto>{
      ...previous,
      ...current,
    }) {
      await _flutterLocalNotificationsPlugin.cancel(
        id: _medicationNotificationId(reminder.id),
      );
    }

    for (final MedicationReminderDto reminder in current) {
      if (!reminder.enabled) continue;
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        reminder.hour,
        reminder.minute,
      );
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: _medicationNotificationId(reminder.id),
        title: 'Medication reminder',
        body: reminder.dose?.trim().isNotEmpty == true
            ? '${reminder.name} — ${reminder.dose!.trim()}'
            : reminder.name,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            medicationChannelId,
            'Medication reminders',
            channelDescription:
                'Daily reminders for medication recorded in your care plan.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '/safety-plan',
      );
    }
  }

  int _medicationNotificationId(String id) {
    int hash = 17;
    for (final int value in id.codeUnits) {
      hash = (hash * 31 + value) & 0x3fffffff;
    }
    return 100000 + hash % 700000;
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      notificationCount.value = 0;
    } catch (e) {
      debugPrint(
        '[LocalNotificationsService] Error cancelling all notifications: $e',
      );
    }
  }

  @override
  void onClose() {
    debugPrint('[LocalNotificationsService] closing');
    super.onClose();
  }
}
