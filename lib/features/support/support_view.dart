import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/constants/support_config.dart';
import 'package:seizure_app/core/services/firebase_messaging_service.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';
import 'package:seizure_app/core/widgets/settings/settings_screen_header.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportView extends StatefulWidget {
  const SupportView({super.key});

  @override
  State<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();
  String? _busyAction;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SettingsScreenHeader(
            title: 'Help & diagnostics',
            backLabel: 'Profile',
            onBack: Get.back,
          ),
          Expanded(
            child: FutureBuilder<PackageInfo>(
              future: _packageInfo,
              builder: (context, snapshot) {
                final PackageInfo? info = snapshot.data;
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    Dimensions.twenty,
                    Dimensions.twentyTwo,
                    Dimensions.twenty,
                    Dimensions.twentyFour,
                  ),
                  children: <Widget>[
                    SettingsSection(
                      label: 'Support',
                      children: <Widget>[
                        SettingsNavRow(
                          icon: Icons.support_agent_outlined,
                          title: 'Contact support',
                          loading: _busyAction == 'support',
                          onTap: () => _contactSupport(info),
                        ),
                        SettingsNavRow(
                          icon: Icons.copy_outlined,
                          title: 'Copy diagnostics',
                          loading: _busyAction == 'copy',
                          onTap: () => _copyDiagnostics(info),
                        ),
                        if (SupportConfig.privacyUrl.isNotEmpty)
                          SettingsNavRow(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy policy',
                            loading: _busyAction == 'privacy',
                            onTap: _openPrivacyPolicy,
                          ),
                      ],
                    ),
                    SizedBox(height: Dimensions.twentySix),
                    SettingsSection(
                      label: 'App',
                      children: <Widget>[
                        SettingsValueRow(
                          icon: Icons.info_outline,
                          label: 'Version',
                          value: info == null
                              ? 'Loading…'
                              : '${info.version} (${info.buildNumber})',
                        ),
                        SettingsValueRow(
                          icon: Icons.phone_android_outlined,
                          label: 'Platform',
                          value: _platformLabel,
                        ),
                        SettingsValueRow(
                          icon: Icons.notifications_outlined,
                          label: 'Push alerts',
                          value: _notificationLabel,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  String get _platformLabel => kIsWeb
      ? 'Web'
      : switch (defaultTargetPlatform) {
          TargetPlatform.android => 'Android',
          TargetPlatform.iOS => 'iOS',
          _ => defaultTargetPlatform.name,
        };

  String get _notificationLabel {
    if (!Get.isRegistered<FirebaseMessagingService>()) return 'Unavailable';
    final FirebaseMessagingService service =
        Get.find<FirebaseMessagingService>();
    if (!service.notificationsAuthorized) return 'Permission needed';
    return service.fcmRegistrationReady.value ? 'Ready' : 'Not registered';
  }

  String _diagnostics(PackageInfo? info) => <String>[
    'Seizure Alert diagnostics',
    'Version: ${info == null ? 'unknown' : '${info.version} (${info.buildNumber})'}',
    'Platform: $_platformLabel',
    'Push alerts: $_notificationLabel',
  ].join('\n');

  Future<void> _copyDiagnostics(PackageInfo? info) async {
    if (_busyAction != null) return;
    setState(() => _busyAction = 'copy');
    try {
      await Clipboard.setData(ClipboardData(text: _diagnostics(info)));
      Get.snackbar(
        'Diagnostics copied',
        'No personal or medical data was included.',
      );
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _contactSupport(PackageInfo? info) async {
    if (_busyAction != null) return;
    setState(() => _busyAction = 'support');
    try {
      if (SupportConfig.email.isEmpty) {
        await Clipboard.setData(ClipboardData(text: _diagnostics(info)));
        Get.snackbar(
          'Support contact unavailable',
          'Diagnostics were copied so you can include them in your report.',
        );
        return;
      }
      final Uri uri = Uri(
        scheme: 'mailto',
        path: SupportConfig.email,
        queryParameters: <String, String>{
          'subject': 'Seizure Alert support',
          'body': '\n\n${_diagnostics(info)}',
        },
      );
      if (!await launchUrl(uri)) {
        await Clipboard.setData(ClipboardData(text: _diagnostics(info)));
      }
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _openPrivacyPolicy() async {
    if (_busyAction != null) return;
    setState(() => _busyAction = 'privacy');
    try {
      await launchUrl(
        Uri.parse(SupportConfig.privacyUrl),
        mode: LaunchMode.externalApplication,
      );
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }
}
