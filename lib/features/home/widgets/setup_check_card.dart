import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/constants/snackbar_margin.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/services/alert_drill_service.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/firebase_messaging_service.dart';
import 'package:seizure_app/features/contacts/view_models/contacts_view_model.dart';

class SetupCheckCard extends GetView<ContactsViewModel> {
  const SetupCheckCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Obx(() {
    final FirebaseMessagingService? messaging =
        Get.isRegistered<FirebaseMessagingService>()
        ? Get.find<FirebaseMessagingService>()
        : null;
    final GenericScreenStates state = controller.screenState.value;
    final int readyCount = controller.contacts
        .where((contact) => contact.isPushReady)
        .length;
    final int testedCount = controller.contacts
        .where(
          (contact) =>
              contact.isPushReady &&
              contact.lastTestStatus == ContactAlertTestStatus.sent,
        )
        .length;
    final int offlineCount = controller.contacts
        .where(
          (contact) =>
              contact.isPushReady &&
              contact.lastTestStatus == ContactAlertTestStatus.deviceOffline,
        )
        .length;
    final int failedCount = controller.contacts
        .where(
          (contact) =>
              contact.isPushReady &&
              contact.lastTestStatus == ContactAlertTestStatus.failed,
        )
        .length;
    final bool contactsLoading =
        state == GenericScreenStates.initial ||
        state == GenericScreenStates.loading;
    final bool contactsFailed = state == GenericScreenStates.error;
    final bool notificationsLoading =
        messaging?.notificationReadinessLoading.value ?? false;
    final AuthorizationStatus? authorization =
        messaging?.notificationAuthorization.value;
    final bool notificationsAuthorized =
        messaging?.notificationsAuthorized ?? false;
    final bool tokenReady = messaging?.fcmRegistrationReady.value ?? false;
    final bool sendingTest = controller.sendingTestAlert.value;
    final String? lastTestSummary = controller.lastTestSummary.value;
    final bool ready =
        !contactsLoading &&
        !contactsFailed &&
        readyCount > 0 &&
        notificationsAuthorized &&
        tokenReady;
    final mode = Get.isRegistered<AppModeService>()
        ? Get.find<AppModeService>() : null;
    final complete = ready && !sendingTest && !notificationsLoading &&
        testedCount == readyCount && offlineCount == 0 && failedCount == 0;
    if (complete && (mode?.hideCompletedSetup.value ?? false)) {
      return const SizedBox.shrink();
    }
    final String title;
    final String detail;
    final String actionLabel;
    final VoidCallback action;

    if (sendingTest) {
      title = 'Sending test alert';
      detail = 'Contacting your connected caregiver devices.';
      actionLabel = 'Sending…';
      action = () {};
    } else if (notificationsLoading) {
      title = 'Checking notification setup';
      detail = 'Confirming this device can receive alerts.';
      actionLabel = 'Checking';
      action = () {};
    } else if (contactsLoading) {
      title = 'Checking emergency contacts';
      detail = 'Checking connected contacts for push alerts.';
      actionLabel = 'Checking';
      action = () {};
    } else if (messaging == null) {
      title = 'Push alerts are unavailable';
      detail = 'Restart the app to restore notification setup.';
      actionLabel = 'Retry';
      action = onTap;
    } else if (authorization == null) {
      title = 'Notification setup could not be checked';
      detail = 'Check your connection, then try again.';
      actionLabel = 'Retry';
      action = messaging.refreshReadiness;
    } else if (!notificationsAuthorized) {
      title = 'Notifications are disabled';
      detail = 'Enable notifications so caregivers can receive alerts.';
      if (authorization == AuthorizationStatus.notDetermined) {
        actionLabel = 'Enable';
        action = messaging.enableNotifications;
      } else {
        actionLabel = 'Open settings';
        action = messaging.openNotificationSettings;
      }
    } else if (!tokenReady) {
      title = 'This device is not ready for alerts';
      detail = 'Check your connection, then retry notification setup.';
      actionLabel = 'Retry';
      action = messaging.refreshReadiness;
    } else if (contactsFailed) {
      title = 'Emergency setup could not be checked';
      detail = 'Open Contacts to review your emergency contacts.';
      actionLabel = 'Contacts';
      action = onTap;
    } else if (readyCount == 0) {
      title = 'No contacts are ready for push alerts';
      detail = 'Add a contact who uses the app, or enable push alerts.';
      actionLabel = 'Contacts';
      action = onTap;
    } else if (offlineCount > 0) {
      title =
          '$offlineCount caregiver ${offlineCount == 1 ? 'device needs' : 'devices need'} attention';
      detail = 'Ask them to reopen the app, then send another test.';
      actionLabel = 'Test again';
      action = () => _confirmAndSendTest(context);
    } else if (testedCount == readyCount) {
      title = 'Caregiver test successful';
      detail =
          'The test reached $testedCount caregiver ${testedCount == 1 ? 'device' : 'devices'}.';
      actionLabel = 'Test again';
      action = () => _confirmAndSendTest(context);
    } else if (failedCount > 0) {
      title = 'Caregiver test incomplete';
      detail = 'One or more caregiver devices could not be reached.';
      actionLabel = 'Test again';
      action = () => _confirmAndSendTest(context);
    } else {
      title = lastTestSummary == null
          ? '$readyCount ${readyCount == 1 ? 'contact' : 'contacts'} connected'
          : 'Test alert sent';
      detail =
          lastTestSummary ?? 'Send a safe test to confirm caregiver delivery.';
      actionLabel = lastTestSummary == null ? 'Test' : 'Test again';
      action = () => _confirmAndSendTest(context);
    }

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.twelve),
        side: const BorderSide(color: Colors.black12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.twelve),
        onTap: () {
          HapticFeedback.selectionClick();
          action();
        },
        child: Padding(
          padding: EdgeInsets.all(Dimensions.sixteen),
          child: Row(
            children: [
              if (sendingTest)
                SizedBox.square(
                  dimension: Dimensions.twentyFour,
                  child: CircularProgressIndicator(
                    strokeWidth: Dimensions.two,
                    color: Colors.black,
                  ),
                )
              else
                Icon(
                  ready
                      ? Icons.check_circle_outline
                      : Icons.notification_important_outlined,
                  color: Colors.black,
                ),
              SizedBox(width: Dimensions.twelve),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Dimensions.four,
                  children: [
                    Text(
                      'Setup check',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      detail,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              SizedBox(width: Dimensions.eight),
              if (complete && mode != null)
                IconButton(
                  tooltip: 'Hide completed setup check',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    mode.setHideCompletedSetup(true);
                  },
                  icon: const Icon(Icons.close),
                ),
              Text(
                actionLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: notificationsLoading || contactsLoading || sendingTest
                      ? Colors.black38
                      : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!notificationsLoading &&
                  !contactsLoading &&
                  !sendingTest) ...[
                SizedBox(width: Dimensions.four),
                const Icon(Icons.chevron_right, color: Colors.black54),
              ],
            ],
          ),
        ),
      ),
    );
  });

  Future<void> _confirmAndSendTest(BuildContext context) async {
    if (controller.sendingTestAlert.value) return;

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Send test alert?'),
            content: const Text(
              'Connected caregivers will receive a notification clearly marked as a test. No emergency alert or seizure record will be created.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Send test'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final result = await controller.sendTestAlert();
    if (!context.mounted) return;

    if (!result.isSuccess || result.data == null) {
      Get.snackbar(
        'Test alert not sent',
        result.error ?? 'Check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: snackbarMargin,
      );
      return;
    }

    final AlertDrillResult drill = result.data!;
    final String message = drill.failedCount == 0
        ? 'Sent to ${drill.sentCount} caregiver ${drill.sentCount == 1 ? 'device' : 'devices'}.'
        : 'Sent to ${drill.sentCount} of ${drill.recipientCount} caregiver devices.';
    Get.snackbar(
      'Test alert sent',
      '$message Device settings can still prevent it from appearing.',
      snackPosition: SnackPosition.BOTTOM,
      margin: snackbarMargin,
    );
  }
}
