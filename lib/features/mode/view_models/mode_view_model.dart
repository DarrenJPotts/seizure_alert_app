import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/services/app_mode_service.dart';
import 'package:seizure_app/core/services/caregiver_service.dart';

class ModeViewModel extends GetxController {
  ModeViewModel(this._appMode, this._caregiverService);

  final AppModeService _appMode;
  final CaregiverService _caregiverService;

  RxBool get caregiverMode => _appMode.caregiverMode;
  final RxBool changingCaregiverMode = false.obs;

  Future<void> setCaregiverMode(bool value) async {
    if (changingCaregiverMode.value) return;

    HapticFeedback.selectionClick();
    changingCaregiverMode.value = true;
    try {
      _caregiverService.invalidateWatchList();
      await _appMode.setCaregiverMode(value);
    } finally {
      changingCaregiverMode.value = false;
    }
  }
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
