import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'firebase_collections_service.dart';
import 'local_notifications_service.dart';

class FirebaseMessagingService extends GetxService {

  LocalNotificationsService? _localNotificationsService;

final fcmToken = Rxn<String>();

final lastNotification = Rxn<RemoteMessage>();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  RemoteMessage? _initialMessage;

Future<FirebaseMessagingService> init({
    required LocalNotificationsService localNotificationsService,
  }) async {
    _localNotificationsService = localNotificationsService;

    try {
      await _handlePushNotificationsToken();

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

FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

FirebaseMessaging.onMessage.listen(_onForegroundMessage);

FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
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
    _authSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    super.onClose();
  }

  Future<void> _handlePushNotificationsToken() async {
    _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      fcmToken.value = newToken;
      _persistToken(newToken);
    });
    await refreshToken();
  }

Future<void> refreshToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        fcmToken.value = token;
        await _persistToken(token);
      }
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

  String? takeInitialNotificationRoute() {
    final RemoteMessage? message = _initialMessage;
    _initialMessage = null;
    return message == null ? null : _notificationRoute(message.data);
  }

  String? _notificationRoute(Map<String, dynamic> data) {
    if (data['type'] == 'circle_invite' && data['inviteId'] != null) {
      return '${AppRoutes.circleInvite}?inviteId=${Uri.encodeQueryComponent(data['inviteId'].toString())}';
    }

    final alertId = data['alertId'];
    if (alertId != null && alertId.isNotEmpty && data['alertType'] == 'sos' && data['alertStatus'] == 'sent') {
      return '${AppRoutes.incomingAlert}?alertId=${Uri.encodeQueryComponent(alertId.toString())}';
    }

    final String? route = data['route'] as String?;
    const Set<String> navigableRoutes = <String>{AppRoutes.alertHistory, AppRoutes.mode, AppRoutes.root};
    return route != null && navigableRoutes.contains(route) ? route : null;
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

String _foregroundPayload(Map<String, dynamic> data) {
    if (data['type'] == 'circle_invite' && data['inviteId'] != null) {
      return '${AppRoutes.circleInvite}?inviteId=${Uri.encodeQueryComponent(data['inviteId'].toString())}';
    }
    if (data['alertType'] == 'sos' &&
        data['alertStatus'] == 'sent' &&
        data['alertId'] != null) {
      return '${AppRoutes.incomingAlert}?alertId=${Uri.encodeQueryComponent(data['alertId'].toString())}';
    }
    return data.toString();
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FirebaseMessagingService] Notification caused app to open: ${message.data}');
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
  debugPrint('[FirebaseMessagingService] Background message received: ${message.data}');
}
