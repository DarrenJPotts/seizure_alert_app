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
  FirebaseMessagingService({
    FirebaseMessaging? messaging,
    FirestoreService? firestore,
    String? Function()? currentUid,
  }) : _injectedMessaging = messaging,
       _injectedFirestore = firestore,
       _injectedUid = currentUid;
  final FirebaseMessaging? _injectedMessaging;
  final FirestoreService? _injectedFirestore;
  final String? Function()? _injectedUid;
  FirebaseMessaging get _messaging =>
      _injectedMessaging ?? FirebaseMessaging.instance;
  FirestoreService get _firestore =>
      _injectedFirestore ?? FirestoreService.instance();
  String? get _uid => _injectedUid != null
      ? _injectedUid()
      : FirebaseAuth.instance.currentUser?.uid;
  Future<void> _revokingToken = Future<void>.value();
  static const Duration _readinessTimeout = Duration(seconds: 10);

  LocalNotificationsService? _localNotificationsService;

  final fcmToken = Rxn<String>();
  final lastNotification = Rxn<RemoteMessage>();
  final notificationAuthorization = Rxn<AuthorizationStatus>();
  final notificationReadinessLoading = true.obs;
  final fcmRegistrationReady = false.obs;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  bool _initialized = false;
  RemoteMessage? _initialMessage;
  Future<void>? _readinessRefresh;
  Future<void>? _tokenRefresh;
  Future<void> _tokenWrites = Future<void>.value();
  bool _endingSession = false;

  bool get notificationsAuthorized {
    final status = notificationAuthorization.value;
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  Future<FirebaseMessagingService> init({
    required LocalNotificationsService localNotificationsService,
  }) async {
    if (_initialized || isClosed) return this;
    _initialized = true;
    _localNotificationsService = localNotificationsService;
    WidgetsBinding.instance.addObserver(this);

    try {
      await _listenForPushTokenChanges();
      await refreshReadiness();
      if (isClosed) return this;

      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
        user,
      ) {
        if (user != null) {
          _endingSession = false;
          unawaited(refreshReadiness());
        } else {
          unawaited(_clearSignedOutNotifications());
        }
      });

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _onForegroundMessage,
      );
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _onMessageOpenedApp,
      );

      final initialMessage = await _messaging.getInitialMessage();
      if (isClosed) return this;
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
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshReadiness());
    }
  }

  Future<void> _listenForPushTokenChanges() async {
    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((newToken) {
      if (isClosed || _endingSession || _uid == null) return;
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
      final settings = await _messaging.getNotificationSettings().timeout(
        _readinessTimeout,
      );
      if (isClosed) return;
      notificationAuthorization.value = settings.authorizationStatus;
      if (notificationsAuthorized && !_endingSession && _uid != null) {
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
      if (!isClosed) notificationReadinessLoading.value = false;
    }
  }

  Future<void> enableNotifications() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (isClosed) return;
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

  Future<void> refreshToken() =>
      _tokenRefresh ??= _performTokenRefresh().whenComplete(() {
        _tokenRefresh = null;
      });

  Future<void> _performTokenRefresh() async {
    if (isClosed || _endingSession || _uid == null) return;
    try {
      await _revokingToken;
      if (isClosed || _endingSession || _uid == null) return;
      await _messaging.setAutoInitEnabled(true);
      final token = await _messaging.getToken().timeout(_readinessTimeout);
      if (!isClosed && token != null && !_endingSession && _uid != null) {
        fcmToken.value = token;
        fcmRegistrationReady.value = true;
        await _persistToken(token);
      } else {
        fcmRegistrationReady.value = false;
      }
    } catch (e) {
      fcmRegistrationReady.value = false;
      debugPrint('[FirebaseMessagingService] Error fetching FCM token: $e');
    }
  }

  Future<void> _persistToken(String token) {
    final uid = _uid;
    final operation = _tokenWrites.then((_) async {
      if (isClosed || _endingSession || uid == null || _uid != uid) return;
      final result = await _firestore.updateFcmToken(uid, token);
      if (!isClosed && uid == _uid) {
        fcmRegistrationReady.value = result.isSuccess;
      }
    });
    _tokenWrites = operation.catchError((Object _) {});
    return operation;
  }

  /// Fail sign-out closed if the server cannot detach this installation.
  Future<void> prepareForSignOut() async {
    _endingSession = true;
    try {
      await _tokenRefresh?.timeout(_readinessTimeout);
      await _tokenWrites.timeout(_readinessTimeout);
      final uid = _uid;
      if (uid != null) {
        final token =
            fcmToken.value ??
            await _messaging.getToken().timeout(_readinessTimeout);
        await _firestore.detachFcmToken(uid, token).timeout(_readinessTimeout);
      }
      await _messaging.setAutoInitEnabled(false);
      await _messaging.deleteToken().timeout(_readinessTimeout);
      fcmToken.value = null;
      fcmRegistrationReady.value = false;
      lastNotification.value = null;
      _initialMessage = null;
      await _localNotificationsService?.cancelAllNotifications();
    } catch (_) {
      _endingSession = false;
      rethrow;
    }
  }

  Future<void> _clearSignedOutNotifications() =>
      _revokingToken = _revokeSignedOutToken();

  Future<void> _revokeSignedOutToken() async {
    _endingSession = true;
    fcmRegistrationReady.value = false;
    lastNotification.value = null;
    _initialMessage = null;
    try {
      await _messaging.setAutoInitEnabled(false);
      await _messaging.deleteToken().timeout(_readinessTimeout);
      fcmToken.value = null;
      await _localNotificationsService?.cancelAllNotifications();
    } catch (_) {
      debugPrint(
        '[FirebaseMessagingService] Could not revoke signed-out push token',
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
    if (isClosed) return;
    if (isClosed || _endingSession || _uid == null) return;
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
    if (isClosed) return;
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
