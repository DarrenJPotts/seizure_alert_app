import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'firebase_collections_service.dart';
import 'local_notifications_service.dart';

class FirebaseMessagingService extends GetxService {
  // Reference to local notifications service
  LocalNotificationsService? _localNotificationsService;

  // Reactive FCM token
  final fcmToken = Rxn<String>();

  // Reactive notification data
  final lastNotification = Rxn<RemoteMessage>();

  StreamSubscription<User?>? _authSubscription;

  /// Initialize Firebase Messaging
  Future<FirebaseMessagingService> init({
    required LocalNotificationsService localNotificationsService,
  }) async {
    _localNotificationsService = localNotificationsService;

    try {
      await _handlePushNotificationsToken();
      await _requestPermission();

      // getToken() may resolve before a user has signed in this session
      // (e.g. right after a fresh install, before signup/login), so
      // _persistToken's uid check skips the write. Re-attempt whenever the
      // auth state changes to a signed-in user so the token still reaches
      // Firestore without requiring an app restart.
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
        final token = fcmToken.value;
        if (user != null && token != null) {
          _persistToken(token);
        }
      });

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
    } catch (e) {
      debugPrint('[FirebaseMessagingService] Error initializing: $e');
    }

    return this;
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  Future<void> _handlePushNotificationsToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        fcmToken.value = token;
        await _persistToken(token);
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        fcmToken.value = newToken;
        _persistToken(newToken);
      });
    } catch (e) {
      debugPrint('[FirebaseMessagingService] Error fetching FCM token: $e');
    }
  }

  Future<void> _persistToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    final result = await FirestoreService.instance().updateFcmToken(uid, token);
    if (!result.isSuccess) {
      debugPrint('[FirebaseMessagingService] Error persisting FCM token: ${result.error}');
    }
  }

  Future<void> _requestPermission() async {
    try {
      final result = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FirebaseMessagingService] User granted permission: ${result.authorizationStatus}');
    } catch (e) {
      debugPrint('[FirebaseMessagingService] Error requesting permission: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[FirebaseMessagingService] Foreground message received: ${message.data}');
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

  /// Builds a bare route (with query params) the foreground tap handler
  /// (`LocalNotificationsService`) can act on — it only navigates when the
  /// payload literally starts with `/`. Other notification types fall back
  /// to the pre-existing stringified data map, which is not actionable.
  String _foregroundPayload(Map<String, dynamic> data) {
    if (data['type'] == 'circle_invite' && data['inviteId'] != null) {
      return '${AppRoutes.circleInvite}?inviteId=${data['inviteId']}';
    }
    if (data['alertType'] == 'sos' &&
        data['alertStatus'] == 'sent' &&
        data['alertId'] != null) {
      return '${AppRoutes.incomingAlert}?alertId=${data['alertId']}';
    }
    return data.toString();
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FirebaseMessagingService] Notification caused app to open: ${message.data}');
    lastNotification.value = message;

    // Navigation with GetX
    _handleNotificationNavigation(message);
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;

    if (data['type'] == 'circle_invite' && data['inviteId'] != null) {
      Get.toNamed(AppRoutes.circleInvite, arguments: {'inviteId': data['inviteId']});
      return;
    }

    final alertId = data['alertId'];
    final alertType = data['alertType'];
    final alertStatus = data['alertStatus'];
    if (alertId != null &&
        alertId.isNotEmpty &&
        alertType == 'sos' &&
        alertStatus == 'sent') {
      Get.toNamed(AppRoutes.incomingAlert, arguments: {'alertId': alertId});
      return;
    }

    const Set<String> navigableRoutes = <String>{
      AppRoutes.alertHistory,
      AppRoutes.mode,
      AppRoutes.root,
    };

    final String? route = data['route'] as String?;
    if (route != null && navigableRoutes.contains(route)) {
      Get.toNamed(route);
    }
  }
}

// Background handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FirebaseMessagingService] Background message received: ${message.data}');
}
