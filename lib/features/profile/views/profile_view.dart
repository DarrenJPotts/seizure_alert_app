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

    if (state == GenericScreenStates.loading || state == GenericScreenStates.initial) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    if (state == GenericScreenStates.error || controller.user.value == null) {
      return SettingsScreenPlaceholder(
        icon: Icons.error_outline,
        message: controller.errorMessage.value ?? 'Something went wrong',
        action: TextButton(
          onPressed: controller.fetchProfile,
          style: TextButton.styleFrom(foregroundColor: Colors.black),
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
            padding: EdgeInsets.fromLTRB(
              Dimensions.twenty,
              Dimensions.twentyTwo,
              Dimensions.twenty,
              Dimensions.twentyFour,
            ),
            children: <Widget>[
              _IdentityCard(user: user),
              SizedBox(height: Dimensions.twentySix),
              _ContactSection(user: user),
              SizedBox(height: Dimensions.twentySix),
              _MedicalSection(user: user),
              SizedBox(height: Dimensions.twentySix),
              const _SettingsSection(),
              SizedBox(height: Dimensions.twentySix),
              const _DangerSection(),
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
    padding: EdgeInsets.symmetric(vertical: Dimensions.twentyFour, horizontal: Dimensions.twenty),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: <Widget>[
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
          alignment: Alignment.center,
          child: Text(
            _initials(user.displayName),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: Dimensions.fourteen),
        Text(
          user.displayName ?? 'No name',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: Dimensions.two),
        Text(
          user.email,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
        SizedBox(height: Dimensions.fourteen),
        OutlinedButton.icon(
          onPressed: () => EditProfileBottomSheet.show(
            user: controller.user.value,
            onSave: controller.updateProfile,
          ),
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Edit profile'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: BorderSide(color: Colors.black.withValues(alpha: 0.2)),
            padding: EdgeInsets.symmetric(horizontal: Dimensions.eighteen, vertical: Dimensions.ten),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.circular)),
          ),
        ),
      ],
    ),
  );

  String _initials(String? name) {
    final List<String> parts = (name ?? '').trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
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
            value: user.medications.isNotNullOrEmpty ? user.medications!.join(', ') : 'Not set',
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
        ],
      ),
      SizedBox(height: Dimensions.ten),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: Dimensions.two),
        child: Text(
          'Your circle sees this when you send an SOS. The emergency note is also read as your care plan '
          'by whoever arrives first, so write it as steps.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 13,
            height: 1.5,
            color: Colors.black.withValues(alpha: 0.45),
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
        SettingsNavRow(
          icon: Icons.shield_outlined,
          title: 'Mode',
          trailingText: AppModeService.instance().caregiverMode.value ? 'Caregiver' : 'Personal',
          onTap: () => Get.toNamed(AppRoutes.mode),
        ),
        SettingsValueRow(
          icon: controller.notificationsEnabled.value
              ? Icons.notifications_outlined
              : Icons.notifications_off_outlined,
          label: 'Notifications',
          value: controller.notificationsLabel,
          valueColor: controller.notificationsEnabled.value ? null : Colors.red.shade400,
          onTap: controller.requestNotifications,
        ),
        SettingsValueRow(
          icon: controller.locationEnabled.value ? Icons.location_on_outlined : Icons.location_off_outlined,
          label: 'Location',
          value: controller.locationLabel,
          valueColor: controller.locationEnabled.value ? null : Colors.red.shade400,
          onTap: controller.requestLocation,
        ),
        SettingsNavRow(
          icon: Icons.key_outlined,
          title: 'Password',
          onTap: () => ChangePasswordSheet.show(onChangePassword: controller.changePassword),
        ),
        SettingsNavRow(
          icon: Icons.lock_outline,
          title: 'Privacy',
          trailingText: _consentLabel(controller.user.value),
          onTap: () => PrivacyNoticeSheet.show(context),
        ),
      ],
    ),
  );

  static String _consentLabel(UserDto? user) {
    final DateTime? at = user?.privacyConsentAt;
    if (at == null) return 'Not recorded';
    if (user?.privacyConsentVersion != PrivacyNotice.version) return 'Update available';
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
        onTap: () => DeleteAccountSheet.show(onDelete: controller.deleteAccount),
      ),
    ],
  );
}
