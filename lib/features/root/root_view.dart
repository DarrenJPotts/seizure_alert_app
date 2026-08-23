import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/controllers/firebase_auth_controller/firebase_auth_controller.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/services/circle_invite_service.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/features/contacts/contacts_view.dart';
import 'package:seizure_app/features/contacts/view_models/contacts_view_model.dart';
import 'package:seizure_app/features/home/home_view.dart';
import 'package:seizure_app/features/home/view_models/home_view_model.dart';
import 'package:seizure_app/features/profile/view_models/profile_view_model.dart';
import 'package:seizure_app/features/profile/views/profile_view.dart';
import 'package:seizure_app/features/root/widgets/floating_bottom_nav_widget.dart';
import 'package:seizure_app/features/seizure_log/seizure_log_view.dart';
import 'package:seizure_app/features/seizure_log/view_models/seizure_log_view_model.dart';
import 'package:seizure_app/features/sos/sos_view.dart';
import 'package:seizure_app/features/sos/view_models/sos_view_model.dart';

class RootViewModel extends GetxController {
  RootViewModel() {
    Get.lazyPut(() => ProfileViewModel(FirestoreService.instance()));
    Get.lazyPut(() => HomeViewModel(FirestoreService.instance()));
    Get.lazyPut(() => SeizureLogViewModel(FirestoreService.instance()));
    Get.lazyPut(
      () => ContactsViewModel(
        FirestoreService.instance(),
        CircleInviteService.instance(),
      ),
    );
    Get.lazyPut(() => SosViewModel());
  }

  final currentIndex = 2.obs;
  final RxBool ready = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ready.value = true;
      return;
    }

    final result = await FirestoreService.instance().getUser(uid);
    if (!result.isSuccess || result.data == null) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }

    ready.value = true;
  }

  void changePage(int index) {
    currentIndex.value = index;
  }
}

class RootView extends StatelessWidget {
  RootView({super.key});

  final viewModel = Get.put(RootViewModel());

  @override
  Widget build(BuildContext context) => Obx(() {
    if (!viewModel.ready.value) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }
    return _buildScaffold(context);
  });

  Widget _buildScaffold(BuildContext context) => Scaffold(
    appBar: AppBar(
      elevation: 0,
      foregroundColor: Colors.black,
      title: const _MonitoringBadge(),
      centerTitle: false,
      actionsPadding: EdgeInsets.only(right: Dimensions.twelve),
      actions: [
        IconButton(
          onPressed: () => Get.toNamed(AppRoutes.caregiverMode),
          icon: const Icon(Icons.supervisor_account_outlined),
          tooltip: 'Caregiver mode',
        ),
        IconButton(
          onPressed: () => Get.toNamed(AppRoutes.alertHistory),
          icon: const Icon(Icons.history),
          tooltip: 'Alert history',
        ),
        IconButton(
          onPressed: () => _confirmSignOut(context),
          icon: const Icon(Icons.logout),
          tooltip: 'Sign out',
        ),
      ],
    ),
    body: Obx(
      () => IndexedStack(
        index: viewModel.currentIndex.value,
        children: [
          const HomeView(),
          const SeizureLogView(),
          SosView(viewModel: viewModel),
          const ContactsView(),
          const ProfileView(),
        ],
      ),
    ),
    bottomNavigationBar: FloatingBottomNavWidget(controller: viewModel),
  );

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to continue monitoring.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuthController.instance().signOut();
    }
  }
}

class _MonitoringBadge extends StatelessWidget {
  const _MonitoringBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.greenAccent,
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.6),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Monitoring Active',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
