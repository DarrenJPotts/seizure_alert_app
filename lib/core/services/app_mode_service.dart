import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/shared_pref_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppModeService extends GetxService {
  AppModeService(this._prefs);

  static AppModeService instance() => Get.find<AppModeService>();

  final SharedPreferences _prefs;

  late final RxBool caregiverMode = RxBool(_prefs.getBool(SharedPrefKeys.caregiverMode) ?? false);

  late final RxBool autoAnswerCalls = RxBool(_prefs.getBool(SharedPrefKeys.autoAnswerCalls) ?? false);

  late final RxBool onboardingCompleted = RxBool(
    _prefs.getBool(SharedPrefKeys.onboardingCompleted) ?? false,
  );

  Future<AppModeService> init() async => this;

  Future<void> setOnboardingCompleted(bool value) async {
    if (onboardingCompleted.value == value) return;
    onboardingCompleted.value = value;
    await _write(SharedPrefKeys.onboardingCompleted, value);
  }

  Future<void> setCaregiverMode(bool value) async {
    if (caregiverMode.value == value) return;
    caregiverMode.value = value;
    await _write(SharedPrefKeys.caregiverMode, value);
  }

  Future<void> setAutoAnswerCalls(bool value) async {
    if (autoAnswerCalls.value == value) return;
    autoAnswerCalls.value = value;
    await _write(SharedPrefKeys.autoAnswerCalls, value);
  }

  Future<void> _write(String key, bool value) async {
    try {
      await _prefs.setBool(key, value);
    } catch (e) {
      debugPrint('[AppModeService] Could not persist $key: $e');
    }
  }
}
