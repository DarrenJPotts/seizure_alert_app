import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/services/firebase_messaging_service.dart';
import 'package:seizure_app/core/services/local_notifications_service.dart';
import 'package:seizure_app/features/caregiver/view_models/caregiver_view_model.dart';

class CaregiverReadinessCard extends StatefulWidget {
  const CaregiverReadinessCard({super.key});

  @override
  State<CaregiverReadinessCard> createState() => _CaregiverReadinessCardState();
}

class _CaregiverReadinessCardState extends State<CaregiverReadinessCard> {
  bool _pressed = false;
  bool _testing = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final CaregiverViewModel controller = Get.find<CaregiverViewModel>();
    final FirebaseMessagingService? messaging =
        Get.isRegistered<FirebaseMessagingService>()
        ? Get.find<FirebaseMessagingService>()
        : null;
    final _ReadinessContent content = _content(controller, messaging);
    final bool enabled = content.action != null && !content.loading;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color foreground = _pressed
        ? scheme.onInverseSurface
        : scheme.onSurface;
    final Color secondary = _pressed
        ? scheme.onInverseSurface.withValues(alpha: 0.7)
        : scheme.onSurfaceVariant;

    return Semantics(
      button: enabled,
      enabled: enabled,
      excludeSemantics: true,
      label: '${content.title}. ${content.detail}',
      onTap: enabled ? content.action : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled
            ? (_) {
                HapticFeedback.selectionClick();
                _setPressed(true);
              }
            : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: enabled ? content.action : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(Dimensions.sixteen),
          decoration: BoxDecoration(
            color: _pressed
                ? scheme.inverseSurface
                : context.design.raisedSurfaces
                ? context.cardSurface
                : scheme.surface,
            boxShadow: _pressed ? const [] : context.designShadows,
            border: Border.all(
              color: _pressed ? scheme.inverseSurface : scheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(
              context.design.raisedSurfaces
                  ? context.design.cardRadius
                  : Dimensions.twelve,
            ),
          ),
          child: Row(
            children: <Widget>[
              if (content.loading)
                SizedBox.square(
                  dimension: Dimensions.twentyFour,
                  child: CircularProgressIndicator(
                    strokeWidth: Dimensions.two,
                    color: foreground,
                  ),
                )
              else
                Icon(content.icon, color: foreground),
              const SizedBox(width: Dimensions.twelve),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'ALERT READINESS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: secondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: Dimensions.four),
                    Text(
                      content.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Dimensions.four),
                    Text(
                      content.detail,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: secondary),
                    ),
                  ],
                ),
              ),
              if (content.actionLabel != null) ...<Widget>[
                const SizedBox(width: Dimensions.eight),
                Text(
                  content.actionLabel!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: Dimensions.four),
                Icon(
                  Icons.chevron_right,
                  color: secondary,
                  size: Dimensions.twenty,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  });

  _ReadinessContent _content(
    CaregiverViewModel controller,
    FirebaseMessagingService? messaging,
  ) {
    if (_testing) {
      return const _ReadinessContent(
        title: 'Sending test alert',
        detail: 'Asking this device to present a local notification.',
        icon: Icons.notifications_active_outlined,
        loading: true,
      );
    }

    final GenericScreenStates state = controller.screenState.value;
    final bool watchListLoading =
        controller.watchListRefreshing.value ||
        state == GenericScreenStates.initial ||
        state == GenericScreenStates.loading;

    if (messaging == null) {
      return const _ReadinessContent(
        title: 'Push alerts are unavailable',
        detail: 'Restart the app to restore notification setup.',
        icon: Icons.notifications_off_outlined,
      );
    }

    if (messaging.notificationReadinessLoading.value) {
      return const _ReadinessContent(
        title: 'Checking notification setup',
        detail: 'Confirming this device can receive alerts.',
        icon: Icons.notifications_outlined,
        loading: true,
      );
    }

    final AuthorizationStatus? authorization =
        messaging.notificationAuthorization.value;
    if (authorization == null) {
      return _ReadinessContent(
        title: 'Notification setup could not be checked',
        detail: 'Check your connection, then try again.',
        icon: Icons.error_outline,
        actionLabel: 'Retry',
        action: messaging.refreshReadiness,
      );
    }

    if (!messaging.notificationsAuthorized) {
      final bool canRequest =
          authorization == AuthorizationStatus.notDetermined;
      return _ReadinessContent(
        title: 'Notifications are disabled',
        detail: 'Enable notifications to receive emergency alerts.',
        icon: Icons.notifications_off_outlined,
        actionLabel: canRequest ? 'Enable' : 'Settings',
        action: canRequest
            ? messaging.enableNotifications
            : messaging.openNotificationSettings,
      );
    }

    if (!messaging.fcmRegistrationReady.value) {
      return _ReadinessContent(
        title: 'This device is not registered for alerts',
        detail: 'Check your connection, then retry notification setup.',
        icon: Icons.sync_problem_outlined,
        actionLabel: 'Retry',
        action: messaging.refreshReadiness,
      );
    }

    if (watchListLoading) {
      return const _ReadinessContent(
        title: 'Checking your watch list',
        detail: 'Confirming who can send alerts to this device.',
        icon: Icons.shield_outlined,
        loading: true,
      );
    }

    if (controller.watchListRefreshFailed.value ||
        state == GenericScreenStates.error) {
      return _ReadinessContent(
        title: 'Watch list could not be confirmed',
        detail: 'Reconnect and refresh before relying on caregiver alerts.',
        icon: Icons.cloud_off_outlined,
        actionLabel: 'Retry',
        action: () => controller.loadPeopleIWatch(forceRefresh: true),
      );
    }

    if (controller.people.isEmpty) {
      return _ReadinessContent(
        title: 'No one is connected yet',
        detail: 'Enter an invite code to start receiving their alerts.',
        icon: Icons.person_add_alt_outlined,
        actionLabel: 'Enter code',
        action: () => Get.toNamed(AppRoutes.circleInvite),
      );
    }

    final int count = controller.people.length;
    return _ReadinessContent(
      title: 'Ready to receive alerts',
      detail:
          'Watching $count ${count == 1 ? 'person' : 'people'}. Test this device before relying on alerts.',
      icon: Icons.check_circle_outline,
      actionLabel: 'Test',
      action: _sendTestAlert,
    );
  }

  Future<void> _sendTestAlert() async {
    if (_testing) return;

    if (!Get.isRegistered<LocalNotificationsService>()) {
      Get.snackbar(
        'Test alert unavailable',
        'Restart the app, then try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: context.ink,
        colorText: context.paper,
      );
      return;
    }

    setState(() => _testing = true);
    try {
      await Get.find<LocalNotificationsService>().showNotification(
        'Test caregiver alert',
        'This device can display caregiver notifications.',
        null,
      );
      if (!mounted) return;
      Get.snackbar(
        'Test notification requested',
        'If it does not appear, review notification and sound settings.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: context.ink,
        colorText: context.paper,
      );
    } catch (_) {
      if (!mounted) return;
      Get.snackbar(
        'Test alert unavailable',
        'Review notification settings, then try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: context.ink,
        colorText: context.paper,
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }
}

class _ReadinessContent {
  const _ReadinessContent({
    required this.title,
    required this.detail,
    required this.icon,
    this.actionLabel,
    this.action,
    this.loading = false,
  });

  final String title;
  final String detail;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? action;
  final bool loading;
}
