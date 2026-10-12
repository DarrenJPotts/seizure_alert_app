import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/dtos/heads_up_dto.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HomeWidgetAction { sos, alert, setup, openApp }

enum HomeWidgetSafetyState { allClear, headsUp, sos, setupRequired, signedOut }

class HomeWidgetService extends GetxService with WidgetsBindingObserver {
  static const String androidProviderName = 'SeizureAlertWidgetProvider';
  static const String iosWidgetName = 'SeizureAlertWidget';
  static const String iosAppGroupId = 'group.com.darren.potts.seizureApp';

  static const String _activeSosKey = 'active_sos';
  static const String _activeHeadsUpKey = 'active_heads_up';
  static const String _setupReadyKey = 'widget_setup_ready';
  static const String _stateKey = 'widget_state';
  static const String _titleKey = 'widget_title';
  static const String _detailKey = 'widget_detail';
  static const String _updatedKey = 'widget_updated';
  static const String _actionLabelKey = 'widget_action_label';
  static const String _actionUriKey = 'widget_action_uri';

  final pendingAction = Rxn<HomeWidgetAction>();

  StreamSubscription<Uri?>? _clickSubscription;
  StreamSubscription<User?>? _authSubscription;
  Worker? _modeWorker;
  bool _setupReady = false;
  String? _lastHandledUri;
  DateTime? _lastHandledAt;

  Future<HomeWidgetService> init() async {
    WidgetsBinding.instance.addObserver(this);
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(iosAppGroupId);
      }
      _setupReady =
          await HomeWidget.getWidgetData<bool>(
            _setupReadyKey,
            defaultValue: false,
          ) ??
          false;
    } catch (error) {
      _setupReady = false;
      debugPrint(
        '[HomeWidgetService] Could not initialise widget data: $error',
      );
    }

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      unawaited(syncCurrentState());
    });
    _modeWorker = ever<bool>(AppModeService.instance().caregiverMode, (_) {
      unawaited(syncCurrentState());
    });

    _handleWidgetUri(await HomeWidget.initiallyLaunchedFromHomeWidget());
    _clickSubscription = HomeWidget.widgetClicked.listen(_handleWidgetUri);
    await syncCurrentState();
    return this;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(syncCurrentState());
    }
  }

  Future<void> setSetupReady(bool value) async {
    if (_setupReady == value) return;
    _setupReady = value;
    await HomeWidget.saveWidgetData<bool>(_setupReadyKey, value);
    await syncCurrentState();
  }

  Future<bool> requestPin() async {
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    if (!supported) return false;

    await HomeWidget.requestPinWidget(
      name: androidProviderName,
      androidName: androidProviderName,
      qualifiedAndroidName: 'com.darren.potts.seizure_app.$androidProviderName',
    );
    return true;
  }

  HomeWidgetAction? takePendingAction() {
    final action = pendingAction.value;
    pendingAction.value = null;
    return action;
  }

  Future<void> syncCurrentState() async {
    try {
      final snapshot = await _buildSnapshot();
      await Future.wait(<Future<bool?>>[
        HomeWidget.saveWidgetData<String>(_stateKey, snapshot.state.name),
        HomeWidget.saveWidgetData<String>(_titleKey, snapshot.title),
        HomeWidget.saveWidgetData<String>(_detailKey, snapshot.detail),
        HomeWidget.saveWidgetData<String>(_updatedKey, _updatedLabel()),
        HomeWidget.saveWidgetData<String>(
          _actionLabelKey,
          snapshot.actionLabel,
        ),
        HomeWidget.saveWidgetData<String>(
          _actionUriKey,
          snapshot.actionUri.toString(),
        ),
      ]);
      await HomeWidget.updateWidget(
        androidName: androidProviderName,
        iOSName: iosWidgetName,
      );
    } catch (error) {
      debugPrint('[HomeWidgetService] Could not update widget: $error');
    }
  }

  Future<
    ({
      HomeWidgetSafetyState state,
      String title,
      String detail,
      String actionLabel,
      Uri actionUri,
    })
  >
  _buildSnapshot() async {
    if (FirebaseAuth.instance.currentUser == null) {
      return _snapshot(
        state: HomeWidgetSafetyState.signedOut,
        title: 'Sign in required',
        detail: 'Open the app to continue.',
        actionLabel: 'OPEN',
        action: HomeWidgetAction.openApp,
      );
    }

    if (AppModeService.instance().caregiverMode.value) {
      return _snapshot(
        state: HomeWidgetSafetyState.setupRequired,
        title: 'Patient mode required',
        detail: 'Open the app to change mode.',
        actionLabel: 'OPEN',
        action: HomeWidgetAction.setup,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final sos = _readSos(prefs.getString(_activeSosKey));
    if (sos?.status == AlertStatus.sent) {
      return _snapshot(
        state: HomeWidgetSafetyState.sos,
        title: 'SOS active',
        detail: 'Your alert remains active.',
        actionLabel: 'VIEW',
        action: HomeWidgetAction.alert,
      );
    }

    final headsUp = _readHeadsUp(prefs.getString(_activeHeadsUpKey));
    if (headsUp?.isActive ?? false) {
      return _snapshot(
        state: HomeWidgetSafetyState.headsUp,
        title: 'Heads Up active',
        detail: 'Open the app to check in.',
        actionLabel: 'OPEN',
        action: HomeWidgetAction.alert,
      );
    }

    if (!_setupReady) {
      return _snapshot(
        state: HomeWidgetSafetyState.setupRequired,
        title: 'Setup required',
        detail: 'Connect a contact for push alerts.',
        actionLabel: 'SETUP',
        action: HomeWidgetAction.setup,
      );
    }

    return _snapshot(
      state: HomeWidgetSafetyState.allClear,
      title: 'All clear',
      detail: 'Your circle is ready.',
      actionLabel: 'SOS',
      action: HomeWidgetAction.sos,
    );
  }

  ({
    HomeWidgetSafetyState state,
    String title,
    String detail,
    String actionLabel,
    Uri actionUri,
  })
  _snapshot({
    required HomeWidgetSafetyState state,
    required String title,
    required String detail,
    required String actionLabel,
    required HomeWidgetAction action,
  }) => (
    state: state,
    title: title,
    detail: detail,
    actionLabel: actionLabel,
    actionUri: Uri(
      scheme: 'seizurealert',
      host: 'widget',
      pathSegments: <String>[action.name],
    ),
  );

  AlertDto? _readSos(String? value) {
    if (value == null) return null;
    try {
      return AlertDto.fromMap(jsonDecode(value) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  HeadsUpDto? _readHeadsUp(String? value) {
    if (value == null) return null;
    try {
      return HeadsUpDto.fromMap(jsonDecode(value) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String _updatedLabel() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return 'Updated $hour:$minute';
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null || uri.scheme != 'seizurealert' || uri.host != 'widget') {
      return;
    }

    final now = DateTime.now();
    if (_lastHandledUri == uri.toString() &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 1)) {
      return;
    }
    _lastHandledUri = uri.toString();
    _lastHandledAt = now;

    final value = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    for (final action in HomeWidgetAction.values) {
      if (action.name == value) {
        pendingAction.value = action;
        return;
      }
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _clickSubscription?.cancel();
    _authSubscription?.cancel();
    _modeWorker?.dispose();
    super.onClose();
  }
}
