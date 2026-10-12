import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:app_settings/app_settings.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'firebase_collections_service.dart';
import 'local_notifications_service.dart';

class FirebaseMessagingService extends GetxService with WidgetsBindingObserver {
  static const Duration _readinessTimeout = Duration(seconds: 10);

  LocalNotificationsService? _localNotificationsService;

  final fcmToken = Rxn<String>();
  final lastNotification = Rxn<RemoteMessage>();
  final notificationAuthorization = Rxn<AuthorizationStatus>();
  final notificationReadinessLoading = true.obs;
  final fcmRegistrationReady = false.obs;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  RemoteMessage? _initialMessage;
  Future<void>? _readinessRefresh;

  bool get notificationsAuthorized {
    final status = notificationAuthorization.value;
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  Future<FirebaseMessagingService> init({
    required LocalNotificationsService localNotificationsService,
  }) async {
    _localNotificationsService = localNotificationsService;
    WidgetsBinding.instance.addObserver(this);

    try {
      await _listenForPushTokenChanges();
      await refreshReadiness();

      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
        user,
      ) {
        if (user != null) unawaited(refreshReadiness());
      });

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _initialMessage = initialMessage;
      }
    } catch (e) {
      debugPrint('[FirebaseMessagingService] Error initializing: $e');
    }

    return this;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshReadiness());
    }
  }

  Future<void> _listenForPushTokenChanges() async {
    _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh
        .listen((newToken) {
          fcmToken.value = newToken;
          fcmRegistrationReady.value = true;
          unawaited(_persistToken(newToken));
        });
  }

  Future<void> refreshReadiness() {
    return _readinessRefresh ??= _performReadinessRefresh().whenComplete(() {
      _readinessRefresh = null;
    });
  }

  Future<void> _performReadinessRefresh() async {
    notificationReadinessLoading.value = true;
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings()
          .timeout(_readinessTimeout);
      notificationAuthorization.value = settings.authorizationStatus;
      if (notificationsAuthorized) {
        await refreshToken();
      } else {
        fcmRegistrationReady.value = false;
      }
    } catch (error) {
      fcmRegistrationReady.value = false;
      debugPrint(
        '[FirebaseMessagingService] Error checking notification readiness: $error',
      );
    } finally {
      notificationReadinessLoading.value = false;
    }
  }

  Future<void> enableNotifications() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      notificationAuthorization.value = settings.authorizationStatus;
      await refreshReadiness();
    } catch (error) {
      debugPrint(
        '[FirebaseMessagingService] Error requesting notification permission: $error',
      );
    }
  }

  Future<void> openNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
    await refreshReadiness();
  }

  Future<void> refreshToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken().timeout(
        _readinessTimeout,
      );
      if (token != null) {
        fcmToken.value = token;
        fcmRegistrationReady.value = true;
        unawaited(_persistToken(token));
      } else {
        fcmRegistrationReady.value = false;
      }
    } catch (e) {
      fcmRegistrationReady.value = false;
      debugPrint('[FirebaseMessagingService] Error fetching FCM token: $e');
    }
  }

  Future<void> _persistToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    final result = await FirestoreService.instance().updateFcmToken(uid, token);
    if (!result.isSuccess) {
      debugPrint(
        '[FirebaseMessagingService] Error persisting FCM token: ${result.error}',
      );
    }
  }

  String? takeInitialNotificationRoute() {
    final RemoteMessage? message = _initialMessage;
    _initialMessage = null;
    return message == null ? null : _notificationRoute(message.data);
  }

  String? _notificationRoute(Map<String, dynamic> data) {
    final alertId = data['alertId'];
    if (alertId != null &&
        alertId.isNotEmpty &&
        data['alertType'] == 'sos' &&
        data['alertStatus'] == 'sent') {
      return '${AppRoutes.incomingAlert}?alertId=${Uri.encodeQueryComponent(alertId.toString())}';
    }

    final String? route = data['route'] as String?;
    const Set<String> navigableRoutes = <String>{
      AppRoutes.alertHistory,
      AppRoutes.mode,
      AppRoutes.root,
      AppRoutes.safetyPlan,
    };
    return route != null && navigableRoutes.contains(route) ? route : null;
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint(
      '[FirebaseMessagingService] Foreground message received: ${message.data}',
    );
    lastNotification.value = message;

    final notificationData = message.notification;
    if (notificationData != null) {
      _localNotificationsService?.showNotification(
        notificationData.title,
        notificationData.body,
        _foregroundPayload(message.data),
      );
    }
  }

  String _foregroundPayload(Map<String, dynamic> data) {
    return _notificationRoute(data) ?? data.toString();
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint(
      '[FirebaseMessagingService] Notification caused app to open: ${message.data}',
    );
    lastNotification.value = message;
    _handleNotificationNavigation(message);
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    final String? route = _notificationRoute(message.data);
    if (route != null) Get.toNamed(route);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '[FirebaseMessagingService] Background message received: ${message.data}',
  );
}
