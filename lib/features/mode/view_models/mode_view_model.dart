import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/invite_dto.dart';
import 'package:seizure_app/core/dtos/watched_person_dto.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/core/services/caregiver_service.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/constants/snackbar_margin.dart';

class ModeViewModel extends GetxController {
  ModeViewModel(this._appMode, this._caregiverService, this._firestoreService);

  final AppModeService _appMode;
  final CaregiverService _caregiverService;
  final FirestoreService _firestoreService;

  RxBool get caregiverMode => _appMode.caregiverMode;
  RxBool get autoAnswerCalls => _appMode.autoAnswerCalls;

  final RxList<WatchedPersonDto> watching = <WatchedPersonDto>[].obs;
  final RxList<InviteDto> pendingInvites = <InviteDto>[].obs;
  final RxBool loadingWatching = true.obs;

  StreamSubscription<List<InviteDto>>? _invitesSub;

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadWatching());
    _listenForInvites();
  }

  @override
  void onClose() {
    _invitesSub?.cancel();
    super.onClose();
  }

  Future<void> _loadWatching() async {
    loadingWatching.value = true;
    final result = await _caregiverService.getPeopleIWatch();
    if (result.isSuccess && result.data != null) watching.value = result.data!.people;
    loadingWatching.value = false;
  }

  void _listenForInvites() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _invitesSub = _firestoreService
        .watchPendingInvites(uid)
        .listen((List<InviteDto> invites) => pendingInvites.value = invites, onError: (_) {});
  }

  Future<void> setCaregiverMode(bool value) async {
    HapticFeedback.selectionClick();
    _caregiverService.invalidateWatchList();
    await _appMode.setCaregiverMode(value);
    unawaited(_loadWatching());
  }

  Future<void> setAutoAnswerCalls(bool value) async {
    HapticFeedback.selectionClick();
    await _appMode.setAutoAnswerCalls(value);
  }

  Future<void> openAlertOverride() => AppSettings.openAppSettings(type: AppSettingsType.notification);

  void openInvite() {
    if (pendingInvites.isEmpty) {
      Get.snackbar(
        'No invites waiting',
        'When someone adds you to their circle, the invite appears here.',
        snackPosition: SnackPosition.BOTTOM,
      margin: snackbarMargin,
      );
      return;
    }
    Get.toNamed(AppRoutes.circleInvite, arguments: <String, String>{'inviteId': pendingInvites.first.id});
  }
}

class ModeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ModeViewModel(AppModeService.instance(), CaregiverService.instance(), FirestoreService.instance()),
    );
  }
}
