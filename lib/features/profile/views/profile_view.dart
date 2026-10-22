import 'package:seizure_app/core/widgets/appearance_sheet.dart';
import 'package:seizure_app/core/widgets/design_style_sheet.dart';
import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/extensions/typed_extensions.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/constants/privacy_notice.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/core/widgets/privacy_notice_sheet.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';
import 'package:seizure_app/core/widgets/settings/settings_screen_header.dart';
import 'package:seizure_app/features/profile/view_models/profile_view_model.dart';

import 'widgets/change_email_sheet.dart';
import 'widgets/change_password_sheet.dart';
import 'widgets/delete_account_sheet.dart';
import 'widgets/edit_profile_bottom_sheet.dart';

class ProfileView extends GetView<ProfileViewModel> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    final GenericScreenStates state = controller.screenState.value;

    if (state == GenericScreenStates.loading ||
        state == GenericScreenStates.initial) {
      return Center(child: CircularProgressIndicator(color: context.ink));
    }

    if (state == GenericScreenStates.error || controller.user.value == null) {
      return SettingsScreenPlaceholder(
        icon: Icons.error_outline,
        message: controller.errorMessage.value ?? 'Something went wrong',
        action: TextButton(
          onPressed: controller.fetchProfile,
          style: TextButton.styleFrom(foregroundColor: context.ink),
          child: const Text('Retry'),
        ),
      );
    }

    final UserDto user = controller.user.value!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SettingsScreenHeader(title: 'Profile'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.twenty,
              Dimensions.twentyTwo,
              Dimensions.twenty,
              Dimensions.twentyFour,
            ),
            children: <Widget>[
              _IdentityCard(user: user),
              const SizedBox(height: Dimensions.twentySix),
              _ContactSection(user: user),
              const SizedBox(height: Dimensions.twentySix),
              _MedicalSection(user: user),
              const SizedBox(height: Dimensions.twentySix),
              const _SettingsSection(),
              const SizedBox(height: Dimensions.twentySix),
              const _DangerSection(),
              const SizedBox(height: Dimensions.twentyFour),
              const DesignVersionFooter(),
            ],
          ),
        ),
      ],
    );
  });
}

class _IdentityCard extends GetView<ProfileViewModel> {
  const _IdentityCard({required this.user});

  final UserDto user;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      vertical: Dimensions.twentyFour,
      horizontal: Dimensions.twenty,
    ),
    decoration: BoxDecoration(
      color: context.paper,
      border: context.designBorder,
      boxShadow: context.designShadows,
      borderRadius: BorderRadius.circular(context.design.featureRadius),
    ),
    child: Column(
      children: <Widget>[
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(shape: BoxShape.circle, color: context.ink),
          alignment: Alignment.center,
          child: Text(
            _initials(user.displayName),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: context.paper,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: Dimensions.fourteen),
        Text(
          user.displayName ?? 'No name',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: Dimensions.two),
        Text(
          user.email,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: context.secondaryInk),
        ),
        const SizedBox(height: Dimensions.fourteen),
        OutlinedButton.icon(
          onPressed: () => EditProfileBottomSheet.show(
            user: controller.user.value,
            onSave: controller.updateProfile,
          ),
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Edit profile'),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.ink,
            side: BorderSide(color: context.ink.withValues(alpha: 0.2)),
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.eighteen,
              vertical: Dimensions.ten,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.circular),
            ),
          ),
        ),
      ],
    ),
  );

  String _initials(String? name) {
    final List<String> parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _ContactSection extends GetView<ProfileViewModel> {
  const _ContactSection({required this.user});

  final UserDto user;

  @override
  Widget build(BuildContext context) => SettingsSection(
    label: 'Contact info',
    children: <Widget>[
      SettingsValueRow(
        icon: Icons.phone_outlined,
        label: 'Phone',
        value: user.phone ?? 'Not set',
        onTap: () => EditProfileBottomSheet.show(
          user: controller.user.value,
          onSave: controller.updateProfile,
        ),
      ),
      SettingsValueRow(
        icon: Icons.email_outlined,
        label: 'Email',
        value: user.email,
        onTap: () => ChangeEmailSheet.show(
          currentEmail: user.email,
          onChangeEmail: controller.changeEmail,
        ),
      ),
      SettingsValueRow(
        icon: controller.emailVerified
            ? Icons.verified_outlined
            : Icons.mark_email_unread_outlined,
        label: 'Email verification',
        value: controller.emailVerified ? 'Verified' : 'Verify',
        loading: controller.isSendingEmailVerification.value,
        onTap: controller.emailVerified
            ? null
            : controller.sendEmailVerification,
      ),
    ],
  );
}

class _MedicalSection extends StatelessWidget {
  const _MedicalSection({required this.user});

  final UserDto user;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SettingsSection(
        label: 'Medical ID',
        children: <Widget>[
          SettingsValueRow(
            icon: Icons.bloodtype_outlined,
            label: 'Blood type',
            value: user.bloodType ?? 'Not set',
          ),
          SettingsValueRow(
            icon: Icons.medication_outlined,
            label: 'Medications',
            value: user.medications.isNotNullOrEmpty
                ? user.medications!.join(', ')
                : 'Not set',
          ),
          SettingsValueRow(
            icon: Icons.warning_amber_outlined,
            label: 'Seizure type',
            value: user.seizureType ?? 'Not set',
          ),
          SettingsValueRow(
            icon: Icons.note_outlined,
            label: 'Emergency note',
            value: user.emergencyNote ?? 'Not set',
          ),
          SettingsNavRow(
            icon: Icons.health_and_safety_outlined,
            title: 'Safety plan & reminders',
            trailingText: user.medicationReminders.isEmpty
                ? 'Set up'
                : '${user.medicationReminders.length} reminders',
            onTap: () async {
              await Get.toNamed(AppRoutes.safetyPlan);
              if (Get.isRegistered<ProfileViewModel>()) {
                await Get.find<ProfileViewModel>().fetchProfile();
              }
            },
          ),
        ],
      ),
      const SizedBox(height: Dimensions.ten),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.two),
        child: Text(
          'Your circle sees this during an SOS. Use the emergency note for first-responder information and the safety plan for caregiver instructions.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 13,
            height: 1.5,
            color: context.secondaryInk,
          ),
        ),
      ),
    ],
  );
}

class _SettingsSection extends GetView<ProfileViewModel> {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) => Obx(
    () => SettingsSection(
      label: 'Settings',
      children: <Widget>[
        const AppearanceSettingsRow(),
        SettingsNavRow(
          icon: Icons.shield_outlined,
          title: 'Mode',
          trailingText: AppModeService.instance().caregiverMode.value
              ? 'Caregiver'
              : 'Personal',
          onTap: () => Get.toNamed(AppRoutes.mode),
        ),
        SettingsValueRow(
          icon: controller.notificationsEnabled.value
              ? Icons.notifications_outlined
              : Icons.notifications_off_outlined,
          label: 'Notifications',
          value: controller.notificationsLabel,
          valueColor: controller.notificationsEnabled.value
              ? null
              : context.secondaryInk,
          loading: controller.isRequestingNotifications.value,
          onTap: controller.requestNotifications,
        ),
        SettingsValueRow(
          icon: controller.locationEnabled.value
              ? Icons.location_on_outlined
              : Icons.location_off_outlined,
          label: 'Location',
          value: controller.locationLabel,
          valueColor: controller.locationEnabled.value
              ? null
              : context.secondaryInk,
          loading: controller.isRequestingLocation.value,
          onTap: controller.requestLocation,
        ),
        SettingsNavRow(
          icon: Icons.widgets_outlined,
          title: 'Home screen widget',
          trailingText: controller.homeWidgetActionLabel,
          loading: controller.isAddingHomeWidget.value,
          onTap: controller.addHomeWidget,
        ),
        SettingsNavRow(
          icon: Icons.health_and_safety_outlined,
          title: 'Safety readiness',
          onTap: () => Get.toNamed(AppRoutes.safetyReadiness),
        ),
        SettingsNavRow(
          icon: Icons.key_outlined,
          title: 'Password',
          onTap: () => ChangePasswordSheet.show(
            onChangePassword: controller.changePassword,
          ),
        ),
        SettingsNavRow(
          icon: Icons.lock_outline,
          title: 'Privacy',
          trailingText: _consentLabel(controller.user.value),
          onTap: () => PrivacyNoticeSheet.show(context),
        ),
        SettingsNavRow(
          icon: Icons.help_outline,
          title: 'Help & diagnostics',
          onTap: () => Get.toNamed(AppRoutes.support),
        ),
      ],
    ),
  );

  static String _consentLabel(UserDto? user) {
    final DateTime? at = user?.privacyConsentAt;
    if (at == null) return 'Not recorded';
    if (user?.privacyConsentVersion != PrivacyNotice.version) {
      return 'Update available';
    }
    return 'Agreed ${at.day}/${at.month}/${at.year}';
  }
}

class _DangerSection extends GetView<ProfileViewModel> {
  const _DangerSection();

  @override
  Widget build(BuildContext context) => SettingsSection(
    children: <Widget>[
      SettingsDestructiveRow(
        icon: Icons.delete_outline,
        title: 'Delete account',
        onTap: () =>
            DeleteAccountSheet.show(onDelete: controller.deleteAccount),
      ),
    ],
  );
}
