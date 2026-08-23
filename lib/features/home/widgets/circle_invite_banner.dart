import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/invite_dto.dart';
import 'package:seizure_app/core/routes/app_routes.dart';

/// Surfaces a pending circle invite on Home so it isn't lost if the
/// recipient dismisses or misses the push notification.
class CircleInviteBanner extends StatelessWidget {
  const CircleInviteBanner({super.key, required this.invite});

  final InviteDto invite;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.circleInvite, arguments: {'inviteId': invite.id}),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(Dimensions.sixteen),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.06),
              ),
              child: const Icon(Icons.group_add_outlined, size: 20, color: Colors.black54),
            ),
            SizedBox(width: Dimensions.twelve),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Circle invite', style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    '${invite.senderName} wants to add you to their circle',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black45),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
