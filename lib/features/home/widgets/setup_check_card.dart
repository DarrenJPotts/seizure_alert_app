import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
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
    final bool ready =
        !contactsLoading &&
        !contactsFailed &&
        readyCount > 0 &&
        notificationsAuthorized &&
        tokenReady;
    final String title;
    final String detail;
    final String actionLabel;
    final VoidCallback action;

    if (notificationsLoading) {
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
    } else {
      title =
          '$readyCount ${readyCount == 1 ? 'contact is' : 'contacts are'} ready';
      detail = 'This device and connected contacts can receive alerts.';
      actionLabel = 'Contacts';
      action = onTap;
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
              Text(
                actionLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: notificationsLoading || contactsLoading
                      ? Colors.black38
                      : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!notificationsLoading && !contactsLoading) ...[
                SizedBox(width: Dimensions.four),
                const Icon(Icons.chevron_right, color: Colors.black54),
              ],
            ],
          ),
        ),
      ),
    );
  });
}
