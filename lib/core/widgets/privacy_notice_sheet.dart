import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/constants/privacy_notice.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';

class PrivacyNoticeSheet extends StatelessWidget {
  const PrivacyNoticeSheet({super.key});

  static Future<void> show(BuildContext context) =>
      AppBottomSheet.show<void>(context: context, builder: (BuildContext _) => const PrivacyNoticeSheet());

  @override
  Widget build(BuildContext context) => AppBottomSheetContent(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          PrivacyNotice.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: Dimensions.twentyFour),
        for (final PrivacyNoticeSection section in PrivacyNotice.sections) ...<Widget>[
          Text(
            section.heading.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
          SizedBox(height: Dimensions.eight),
          Text(
            section.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.55),
          ),
          SizedBox(height: Dimensions.twentyFour),
        ],
        Text(
          'Version ${PrivacyNotice.version}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
        ),
        SizedBox(height: Dimensions.sixteen),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: Get.back<void>,
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Close'),
          ),
        ),
      ],
    ),
  );
}
