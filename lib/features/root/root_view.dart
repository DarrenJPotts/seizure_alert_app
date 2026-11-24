import 'package:seizure_app/features/daily_log/view_models/daily_log_view_model.dart';
import 'package:seizure_app/features/cycle/view_models/cycle_view_model.dart';
import 'package:seizure_app/features/reminders/view_models/reminders_view_model.dart';
import 'package:seizure_app/core/themes/app_palette.dart';
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
import 'package:seizure_app/core/services/local_notifications_service.dart';
import 'package:seizure_app/core/widgets/offline_banner.dart';
import 'package:seizure_app/features/alert_history/alert_history_view.dart';
import 'package:seizure_app/features/alert_history/view_models/alert_history_view_model.dart';
import 'package:seizure_app/features/caregiver/caregiver_view.dart';
import 'package:seizure_app/features/caregiver/view_models/caregiver_view_model.dart';
import 'package:seizure_app/features/contacts/contacts_view.dart';
import 'package:seizure_app/features/contacts/view_models/contacts_view_model.dart';
import 'package:seizure_app/features/heads_up/view_models/heads_up_view_model.dart';
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
    RemindersBinding().dependencies();
    CycleBinding().dependencies();
    DailyLogBinding().dependencies();
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
    Get.lazyPut(() => HeadsUpViewModel(), fenix: true);

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
  Worker? _modeWorker;

  @override
  void onInit() {
    super.onInit();
    if (caregiverMode.value) currentIndex.value = 0;

    _modeWorker = ever<bool>(
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

    Get.find<HeadsUpViewModel>();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ready.value = true;
      return;
    }

    try {
      final result = await FirestoreService.instance().getUser(
        uid,
        requireCompleteProfile: true,
      );
      if (isClosed || FirebaseAuth.instance.currentUser?.uid != uid) return;
      if (result.isSuccess &&
          result.data != null &&
          Get.isRegistered<LocalNotificationsService>()) {
        try {
          await Get.find<LocalNotificationsService>()
              .replaceMedicationReminders(
                previous: [],
                current: result.data!.medicationReminders,
              );
        } catch (_) {
          debugPrint('[RootViewModel] Could not restore medication schedules');
        }
      }
      if (isClosed || FirebaseAuth.instance.currentUser?.uid != uid) return;
      if (!result.isSuccess &&
          (result.error == 'User not found' ||
              result.error == 'Profile incomplete')) {
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

    if (!isClosed && FirebaseAuth.instance.currentUser?.uid == uid) {
      ready.value = true;
      if (Get.isRegistered<LocalNotificationsService>()) {
        final notifications = Get.find<LocalNotificationsService>();
        if (notifications.reminderLaunchRequested) {
          notifications.reminderLaunchRequested = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!isClosed && FirebaseAuth.instance.currentUser?.uid == uid) {
              Get.toNamed(AppRoutes.reminders);
            }
          });
        }
      }
    }
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
      if (isClosed) return;
      if (enableCaregiverMode && Get.isRegistered<CaregiverViewModel>()) {
        final CaregiverViewModel caregiverController =
            Get.find<CaregiverViewModel>();
        if (caregiverController.screenState.value !=
            GenericScreenStates.loading) {
          await caregiverController.loadPeopleIWatch(forceRefresh: true);
        }
      }
    } finally {
      if (!isClosed) switchingMode.value = false;
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
          if (!isClosed) Get.toNamed(AppRoutes.mode);
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
    _modeWorker?.dispose();
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
      foregroundColor: context.ink,
      centerTitle: false,
      title: ModeBadge(
        caregiver: false,
        loading: controller.switchingMode.value,
        onTap: () => _confirmCaregiverMode(context),
      ),
      actionsPadding: const EdgeInsets.only(right: Dimensions.twelve),
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

  /// Caregiver mode hides the SOS button on this phone, so one stray tap on
  /// the badge must not do it silently, and never during an active SOS.
  Future<void> _confirmCaregiverMode(BuildContext context) async {
    final bool sosActive =
        Get.isRegistered<SosViewModel>() &&
        Get.find<SosViewModel>().activeSos.value != null;
    if (sosActive) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Your SOS is active'),
          content: const Text(
            'Cancel your SOS before switching to caregiver mode.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Switch to caregiver mode?'),
        content: const Text(
          'The SOS button will be hidden on this phone until you switch '
          'back. Only switch if you use this phone to look after someone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.ink),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.toggleMode();
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final SosViewModel? sosVm = Get.isRegistered<SosViewModel>()
        ? Get.find<SosViewModel>()
        : null;
    if (sosVm?.activeSos.value != null) {
      await _confirmSignOutDuringSos(context, sosVm!);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Alerts will stop on this phone until you sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.ink),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuthController.instance().signOut();
    }
  }

  /// Signing out mid-SOS used to leave the alert open on the server, so
  /// caregivers kept seeing an SOS and the watch could not send a new one.
  Future<void> _confirmSignOutDuringSos(
    BuildContext context,
    SosViewModel sosVm,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Cancel your SOS and sign out?'),
        content: const Text(
          'Your SOS is still active. Signing out cancels it, and your circle '
          'will be told you are okay. Only do this if you no longer need help.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep SOS active'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
            child: const Text('Cancel SOS and sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final bool cancelled = await sosVm.cancelSosAndConfirm();
    if (!cancelled) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('SOS not cancelled'),
          content: const Text(
            'Your SOS could not be cancelled, so you are still signed in. '
            'Check your connection and try again, or call your circle.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    await FirebaseAuthController.instance().signOut();
  }
}
