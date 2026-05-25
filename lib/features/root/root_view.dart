import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/features/contacts/contacts_view.dart';
import 'package:seizure_app/features/home/home_view.dart';
import 'package:seizure_app/features/profile/view_models/profile_view_model.dart';
import 'package:seizure_app/features/profile/views/profile_view.dart';
import 'package:seizure_app/features/root/widgets/floating_bottom_nav_widget.dart';
import 'package:seizure_app/features/sos/sos_view.dart';

class RootViewModel extends GetxController {
  RootViewModel() {
    Get.lazyPut(() => ProfileViewModel(FirestoreService.instance()));
  }

  final currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;
  }
}

class RootView extends StatelessWidget {
  RootView({super.key});

  final viewModel = Get.put(RootViewModel());

  @override
  Widget build(BuildContext context) =>
      Scaffold(
        appBar: AppBar(
          elevation: 0,
          foregroundColor: Colors.black,
          actionsPadding: EdgeInsets.only(right: Dimensions.twelve),
          actions: [IconButton(onPressed: () {}, icon: Icon(Icons.logout))],
        ),
        body: Obx(
              () =>
              IndexedStack(
                index: viewModel.currentIndex.value,
                children: [
                  HomeView(viewModel: viewModel,),
                  _seizureLogView(context),
                  SosView(viewModel: viewModel),
                  ContactsView(),
                  ProfileView(),
                ],
              ),
        ),
        bottomNavigationBar: FloatingBottomNavWidget(controller: viewModel),
      );

  // ─── Seizure Log ───────────────────────────────────────────────────────────

  Widget _seizureLogView(BuildContext context) {
    // Placeholder — replace with real log entries from ViewModel
    final List<Map<String, String>> mockLogs = [
      {'date': 'Today, 08:14 AM', 'duration': '~2 min', 'location': 'Home'},
      {'date': 'Yesterday, 3:42 PM', 'duration': '~1 min', 'location': 'Work'},
      {'date': 'Apr 25, 11:05 AM', 'duration': '~3 min', 'location': 'Unknown'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.twentyFour,
            Dimensions.twentyFour,
            Dimensions.twentyFour,
            Dimensions.twelve,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Seizure Log', style: Theme
                  .of(context)
                  .textTheme
                  .titleMedium),
              TextButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add, size: 16),
                label: Text('Add entry'),
              ),
            ],
          ),
        ),
        Expanded(
          child: mockLogs.isEmpty
              ? Center(child: Text('No seizures logged yet', style: Theme
              .of(context)
              .textTheme
              .bodyMedium))
              : ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: Dimensions.twentyFour),
            itemCount: mockLogs.length,
            separatorBuilder: (_, __) => SizedBox(height: Dimensions.twelve),
            itemBuilder: (context, index) {
              final log = mockLogs[index];
              return _SeizureLogCard(
                date: log['date']!,
                duration: log['duration']!,
                location: log['location']!,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────
class _SeizureLogCard extends StatelessWidget {
  final String date;
  final String duration;
  final String location;

  const _SeizureLogCard({required this.date, required this.duration, required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.06)),
            child: Icon(Icons.bolt, size: 20, color: Colors.black54),
          ),
          SizedBox(width: Dimensions.twelve),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(date, style: Theme.of(context).textTheme.bodyMedium),
                Text('$duration · $location', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.black26),
        ],
      ),
    );
  }
}

