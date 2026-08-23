import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/watched_person_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/caregiver_service.dart';

class CaregiverViewModel extends GetxController {
  CaregiverViewModel(this._caregiverService);

  final CaregiverService _caregiverService;

  final RxList<WatchedPersonDto> people = <WatchedPersonDto>[].obs;
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;

  @override
  void onInit() {
    super.onInit();
    loadPeopleIWatch();
  }

  Future<void> loadPeopleIWatch({bool forceRefresh = false}) async {
    screenState.value = GenericScreenStates.loading;
    final result = await _caregiverService.getPeopleIWatch(forceRefresh: forceRefresh);
    if (!result.isSuccess || result.data == null) {
      screenState.value = GenericScreenStates.error;
      return;
    }
    people.value = result.data!;
    screenState.value =
        people.isEmpty ? GenericScreenStates.empty : GenericScreenStates.loaded;
  }
}

class CaregiverBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CaregiverViewModel(CaregiverService.instance()));
  }
}
