import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/dimensions.dart';
import '../themes/app_palette.dart';

class AppVersionFooter extends StatefulWidget {
  const AppVersionFooter({super.key});
  @override
  State<AppVersionFooter> createState() => _AppVersionFooterState();
}

class _AppVersionFooterState extends State<AppVersionFooter> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();
  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: _info,
    builder: (context, snapshot) => Padding(
      padding: const EdgeInsets.all(Dimensions.twelve),
      child: Text(
        snapshot.data == null
            ? 'Seizure Alert'
            : 'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
      ),
    ),
  );
}
