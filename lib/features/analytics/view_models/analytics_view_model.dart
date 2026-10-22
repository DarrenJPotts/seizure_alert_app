import 'package:get/get.dart';
import '../../../core/enums/generic_screen_states.dart';
import '../../../core/services/firebase_collections_service.dart';
import '../../home/view_models/home_view_model.dart';
import '../models/analytics_summary.dart';

class AnalyticsViewModel extends GetxController {
  AnalyticsViewModel(this.home, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final HomeViewModel home;
  final DateTime Function() _clock;
  final selectedDays = 30.obs;
  GenericScreenStates get state => home.screenState.value;
  AnalyticsSummary get summary => AnalyticsSummary(
    home.seizureLogs.toList(),
    now: _clock(),
    days: selectedDays.value,
  );
  Future<void> retry() => home.retry();
  void selectDays(int days) {
    if (days == 30 || days == 90) selectedDays.value = days;
  }
}

class AnalyticsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeViewModel>()) {
      Get.lazyPut(
        () => HomeViewModel(FirestoreService.instance()),
        fenix: true,
      );
    }
    Get.lazyPut(() => AnalyticsViewModel(Get.find<HomeViewModel>()));
  }
}
