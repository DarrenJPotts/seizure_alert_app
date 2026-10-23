import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/medication_reminder_dto.dart';
import 'package:seizure_app/core/helpers/reminder_schedule.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationsService extends GetxService
    with WidgetsBindingObserver {
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
  static const String alertChannelId = 'seizure_alerts_v2';
  static const String medicationChannelId = 'medication_reminders';
  static const int nearbyEmergencyNotificationId = 900001;
  final _androidChannel = const AndroidNotificationChannel(
    alertChannelId,
    'Emergency alerts',
    description:
        'SOS alerts, Heads Up check-ins, and missed check-ins from your circle.',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('seizure_alert'),
  );
  final _medicationChannel = const AndroidNotificationChannel(
    medicationChannelId,
    'Reminders',
    description: 'Medication, supplement, appointment, and personal reminders.',
    importance: Importance.high,
  );

  bool _isFlutterLocalNotificationInitialized = false;
  List<MedicationReminderDto> _medicationReminders = <MedicationReminderDto>[];
  Future<void> _reminderOperations = Future<void>.value();

  int _notificationIdCounter = 0;

  final notificationCount = 0.obs;
  final lastNotificationPayload = Rxn<String>();
  bool reminderLaunchRequested = false;

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
      final launch = await _flutterLocalNotificationsPlugin
          .getNotificationAppLaunchDetails();
      reminderLaunchRequested =
          launch?.didNotificationLaunchApp == true &&
          launch?.notificationResponse?.payload == '/reminders';

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
      _isFlutterLocalNotificationInitialized = true;
      WidgetsBinding.instance.addObserver(this);
    } catch (e) {
      debugPrint('[LocalNotificationsService] Error initializing: $e');
    }

    return this;
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
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
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('seizure_alert'),
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
            playSound: true,
            sound: RawResourceAndroidNotificationSound('seizure_alert'),
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
  }) {
    final savedPrevious = List<MedicationReminderDto>.of(previous);
    final savedCurrent = List<MedicationReminderDto>.of(current);
    return _queueReminderOperation(
      () => _replaceMedicationReminders(
        previous: savedPrevious,
        current: savedCurrent,
      ),
    );
  }

  Future<void> _queueReminderOperation(Future<void> Function() operation) {
    final result = _reminderOperations.then((_) => operation());
    _reminderOperations = result.catchError((Object _) {});
    return result;
  }

  Future<void> _replaceMedicationReminders({
    required List<MedicationReminderDto> previous,
    required List<MedicationReminderDto> current,
  }) async {
    if (!_isFlutterLocalNotificationInitialized) {
      throw StateError('Local notifications are unavailable');
    }
    if (current.any((reminder) => reminder.enabled)) {
      final deviceZone = await FlutterTimezone.getLocalTimezone();
      // Resolve before cancelling existing reminders. Never silently use UTC
      // or a fixed regional timezone when device detection fails.
      tz.setLocalLocation(tz.getLocation(deviceZone.identifier));
    }
    final now = tz.TZDateTime.now(tz.local);
    final slots = reminderNotificationSlots(current, now);
    // Resolve rare hash collisions before changing any native schedules.
    final slotIds = <String, int>{};
    final usedIds = <int>{};
    for (final slot in [...slots]..sort((a, b) => a.key.compareTo(b.key))) {
      var id = _medicationNotificationId(slot.key);
      while (!usedIds.add(id)) {
        id = id == 799999 ? 100000 : id + 1;
      }
      slotIds[slot.key] = id;
    }
    final ids = <int>{
      for (final reminder in <MedicationReminderDto>{
        ...previous,
        ..._medicationReminders,
        ...current,
      })
        _medicationNotificationId(reminder.id),
    };
    // Native schedules survive process restarts. Cancel stale medication IDs
    // without touching emergency notifications or writing another health cache.
    final pending = await _flutterLocalNotificationsPlugin
        .pendingNotificationRequests();
    ids.addAll(
      pending
          .where((item) => item.id >= 100000 && item.id < 800000)
          .map((item) => item.id),
    );
    for (final id in ids) {
      await _flutterLocalNotificationsPlugin.cancel(id: id);
    }
    _medicationReminders = List<MedicationReminderDto>.of(current);

    for (final slot in slots) {
      final reminder = slot.reminder;
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: slotIds[slot.key]!,
        title: '${reminder.kindLabel} reminder',
        body: reminder.dose?.trim().isNotEmpty == true
            ? '${reminder.name} — ${reminder.dose!.trim()}'
            : reminder.name,
        scheduledDate: tz.TZDateTime.from(slot.at, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            medicationChannelId,
            'Reminders',
            channelDescription:
                'Medication, supplement, appointment, and personal reminders.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: switch (slot.repeat) {
          ReminderRepeat.once => null,
          ReminderRepeat.daily => DateTimeComponents.time,
          ReminderRepeat.weekly ||
          ReminderRepeat.weekdays => DateTimeComponents.dayOfWeekAndTime,
          ReminderRepeat.monthly => DateTimeComponents.dayOfMonthAndTime,
        },
        payload: '/reminders',
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

  Future<void> clearMedicationReminders() => _queueReminderOperation(() async {
    reminderLaunchRequested = false;
    if (!_isFlutterLocalNotificationInitialized) {
      _medicationReminders = <MedicationReminderDto>[];
      return;
    }
    await _replaceMedicationReminders(
      previous: _medicationReminders,
      current: const <MedicationReminderDto>[],
    );
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(
      _queueReminderOperation(() async {
        if (_medicationReminders.isEmpty) return;
        await _replaceMedicationReminders(
          previous: _medicationReminders,
          current: _medicationReminders,
        );
      }).catchError((Object _) {
        debugPrint(
          '[LocalNotificationsService] Could not refresh medication schedules',
        );
      }),
    );
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
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('[LocalNotificationsService] closing');
    super.onClose();
  }
}
