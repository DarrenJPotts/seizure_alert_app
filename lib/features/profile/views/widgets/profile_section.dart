import 'package:flutter/material.dart';

import 'profile_item.dart';

class ProfileSection extends StatelessWidget {
  final List<ProfileItem> items;

  const ProfileSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
      itemBuilder: (_, index) => items[index],
    ),
  );
}
