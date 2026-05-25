import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/home/widgets/recent_activity_card_widget.dart';
import 'package:seizure_app/features/root/root_view.dart';

import 'widgets/quick_action_card_widget.dart';
import 'widgets/status_card_widget.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.viewModel});

  final RootViewModel viewModel;

  @override
  Widget build(BuildContext context) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(Dimensions.twentyFour),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Dimensions.twentyFour,
          children: [
            /// Status card
            StatusCardWidget(),

            /// Quick actions
            Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
            Row(
              spacing: Dimensions.twelve,
              children: [
                Expanded(child: QuickActionCard(icon: Icons.people_outline, label: 'My Circle', onTap: () => viewModel.changePage(3))),
                Expanded(child: QuickActionCard(icon: Icons.history, label: 'Seizure Log', onTap: () => viewModel.changePage(1))),
                Expanded(child: QuickActionCard(icon: Icons.medical_information_outlined, label: 'Medical ID', onTap: () {})),
              ],
            ),

            /// Recent activity
            Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
            RecentActivityCard(),
          ],
        ),
      );
  }
}
