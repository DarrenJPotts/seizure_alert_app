import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/controllers/firebase_auth_controller/firebase_auth_controller.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/core/services/alert_drill_service.dart';
import 'package:seizure_app/core/services/caregiver_service.dart';
import 'package:seizure_app/core/services/circle_invite_service.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/home_widget_service.dart';
import 'package:seizure_app/core/widgets/offline_banner.dart';
import 'package:seizure_app/features/alert_history/alert_history_view.dart';
import 'package:seizure_app/features/alert_history/view_models/alert_history_view_model.dart';
import 'package:seizure_app/features/caregiver/caregiver_view.dart';
import 'package:seizure_app/features/caregiver/view_models/caregiver_view_model.dart';
import 'package:seizure_app/features/contacts/contacts_view.dart';
import 'package:seizure_app/features/contacts/view_models/contacts_view_model.dart';
import 'package:seizure_app/features/home/home_view.dart';
import 'package:seizure_app/features/home/view_models/home_view_model.dart';
import 'package:seizure_app/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:seizure_app/features/profile/view_models/profile_view_model.dart';
import 'package:seizure_app/features/profile/views/profile_view.dart';
import 'package:seizure_app/features/root/widgets/floating_bottom_nav_widget.dart';
import 'package:seizure_app/features/root/widgets/mode_badge.dart';
import 'package:seizure_app/features/seizure_log/seizure_log_view.dart';
import 'package:seizure_app/features/seizure_log/view_models/seizure_log_view_model.dart';
import 'package:seizure_app/features/sos/sos_view.dart';
import 'package:seizure_app/features/sos/view_models/sos_view_model.dart';
import 'package:seizure_app/features/splash/widgets/splash_body.dart';

class RootBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ProfileViewModel(FirestoreService.instance()),
      fenix: true,
    );
    Get.lazyPut(() => HomeViewModel(FirestoreService.instance()), fenix: true);
    Get.lazyPut(
      () => SeizureLogViewModel(FirestoreService.instance()),
      fenix: true,
    );
    Get.lazyPut(
      () => ContactsViewModel(
        FirestoreService.instance(),
        CircleInviteService.instance(),
        AlertDrillService.instance(),
      ),
      fenix: true,
    );
    Get.lazyPut(() => SosViewModel(), fenix: true);

    Get.lazyPut(
      () => CaregiverViewModel(CaregiverService.instance()),
      fenix: true,
    );
    Get.lazyPut(
      () => AlertHistoryViewModel(
        FirestoreService.instance(),
        CaregiverService.instance(),
        AppModeService.instance(),
      ),
      fenix: true,
    );

    Get.lazyPut(() => RootViewModel(), fenix: true);
  }
}

class RootViewModel extends GetxController {
  final AppModeService _appMode = AppModeService.instance();

  RxBool get caregiverMode => _appMode.caregiverMode;

  final currentIndex = 2.obs;
  final RxBool ready = false.obs;
  final RxBool widgetSosRequested = false.obs;
  final RxBool switchingMode = false.obs;
  bool _widgetSosDialogOpen = false;
  Worker? _widgetActionWorker;

  @override
  void onInit() {
    super.onInit();
    if (caregiverMode.value) currentIndex.value = 0;

    ever<bool>(
      caregiverMode,
      (bool isCaregiver) => currentIndex.value = isCaregiver ? 0 : 2,
    );

    if (Get.isRegistered<HomeWidgetService>()) {
      _widgetActionWorker = ever<HomeWidgetAction?>(
        Get.find<HomeWidgetService>().pendingAction,
        (_) => _handleWidgetAction(),
      );
      _handleWidgetAction();
    }

    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ready.value = true;
      return;
    }

    try {
      final result = await FirestoreService.instance().getUser(uid);
      if (!result.isSuccess && result.error == 'User not found') {
        Get.offAllNamed(
          AppRoutes.onboarding,
          arguments: <String, OnboardingMode>{
            'mode': OnboardingMode.completeProfile,
          },
        );
        return;
      }

      if (!result.isSuccess) {
        debugPrint('[RootViewModel] Could not check profile: ${result.error}');
      }
    } catch (error) {
      debugPrint('[RootViewModel] Could not check profile: $error');
    }

    ready.value = true;
  }

  void changePage(int index) {
    currentIndex.value = index;
  }

  Future<void> toggleMode() async {
    if (switchingMode.value) return;

    switchingMode.value = true;
    final bool enableCaregiverMode = !caregiverMode.value;
    CaregiverService.instance().invalidateWatchList();

    try {
      await _appMode.setCaregiverMode(enableCaregiverMode);
      if (enableCaregiverMode && Get.isRegistered<CaregiverViewModel>()) {
        final CaregiverViewModel caregiverController =
            Get.find<CaregiverViewModel>();
        if (caregiverController.screenState.value !=
            GenericScreenStates.loading) {
          await caregiverController.loadPeopleIWatch(forceRefresh: true);
        }
      }
    } finally {
      switchingMode.value = false;
    }
  }

  bool consumeWidgetSosRequest() {
    if (!widgetSosRequested.value) return false;
    widgetSosRequested.value = false;
    return true;
  }

  void completeWidgetSosRequest() {
    _widgetSosDialogOpen = false;
  }

  void discardWidgetSosRequest() {
    widgetSosRequested.value = false;
    _widgetSosDialogOpen = false;
  }

  void _handleWidgetAction() {
    final service = Get.find<HomeWidgetService>();
    final action = service.takePendingAction();
    if (action == null) return;

    if (caregiverMode.value) {
      if (action != HomeWidgetAction.openApp) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.toNamed(AppRoutes.mode);
        });
      }
      return;
    }

    switch (action) {
      case HomeWidgetAction.sos:
        currentIndex.value = 2;
        if (_widgetSosDialogOpen || widgetSosRequested.value) return;
        _widgetSosDialogOpen = true;
        widgetSosRequested.value = true;
        return;
      case HomeWidgetAction.alert:
        currentIndex.value = 2;
        return;
      case HomeWidgetAction.setup:
        currentIndex.value = 3;
        return;
      case HomeWidgetAction.openApp:
        return;
    }
  }

  @override
  void onClose() {
    _widgetActionWorker?.dispose();
    super.onClose();
  }
}

class RootView extends GetView<RootViewModel> {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    if (!controller.ready.value) {
      return const Scaffold(backgroundColor: Colors.black, body: SplashBody());
    }
    return controller.caregiverMode.value
        ? _buildCaregiverShell()
        : _buildPatientShell(context);
  });

  Widget _buildCaregiverShell() => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Obx(
              () => IndexedStack(
                index: controller.currentIndex.value,
                children: [
                  CaregiverView(
                    onOpenProfile: () => controller.changePage(2),
                    onToggleMode: controller.toggleMode,
                    switchingMode: controller.switchingMode.value,
                  ),
                  const AlertHistoryView(),
                  const ProfileView(),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: FloatingBottomNavWidget(
      controller: controller,
      caregiver: true,
    ),
  );

  Widget _buildPatientShell(BuildContext context) => Scaffold(
    appBar: AppBar(
      elevation: 0,
      foregroundColor: Colors.black,
      centerTitle: false,
      title: ModeBadge(
        caregiver: false,
        loading: controller.switchingMode.value,
        onTap: controller.toggleMode,
      ),
      actionsPadding: EdgeInsets.only(right: Dimensions.twelve),
      actions: [
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
    body: Column(
      children: [
        const OfflineBanner(),
        Expanded(
          child: Obx(
            () => IndexedStack(
              index: controller.currentIndex.value,
              children: [
                HomeView(onOpenContacts: () => controller.changePage(3)),
                const SeizureLogView(),
                SosView(viewModel: controller),
                const ContactsView(),
                const ProfileView(),
              ],
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: FloatingBottomNavWidget(controller: controller),
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
