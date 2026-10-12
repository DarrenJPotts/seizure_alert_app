import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/watched_person_dto.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/core/services/caregiver_service.dart';

class ModeViewModel extends GetxController {
  ModeViewModel(this._appMode, this._caregiverService);

  final AppModeService _appMode;
  final CaregiverService _caregiverService;

  RxBool get caregiverMode => _appMode.caregiverMode;
  RxBool get autoAnswerCalls => _appMode.autoAnswerCalls;

  final RxList<WatchedPersonDto> watching = <WatchedPersonDto>[].obs;
  final RxBool loadingWatching = true.obs;
  final RxBool changingCaregiverMode = false.obs;
  final RxBool changingAutoAnswer = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadWatching());
  }

  Future<void> _loadWatching() async {
    loadingWatching.value = true;
    final result = await _caregiverService.getPeopleIWatch();
    if (result.isSuccess && result.data != null) {
      watching.value = result.data!.people;
    }
    loadingWatching.value = false;
  }

  Future<void> setCaregiverMode(bool value) async {
    if (changingCaregiverMode.value) return;

    HapticFeedback.selectionClick();
    changingCaregiverMode.value = true;
    try {
      _caregiverService.invalidateWatchList();
      await _appMode.setCaregiverMode(value);
      unawaited(_loadWatching());
    } finally {
      changingCaregiverMode.value = false;
    }
  }

  Future<void> setAutoAnswerCalls(bool value) async {
    if (changingAutoAnswer.value) return;

    HapticFeedback.selectionClick();
    changingAutoAnswer.value = true;
    try {
      await _appMode.setAutoAnswerCalls(value);
    } finally {
      changingAutoAnswer.value = false;
    }
  }

  Future<void> openAlertOverride() =>
      AppSettings.openAppSettings(type: AppSettingsType.notification);

  void openInvite() => Get.toNamed(AppRoutes.circleInvite);
}

class ModeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () =>
          ModeViewModel(AppModeService.instance(), CaregiverService.instance()),
    );
  }
}
