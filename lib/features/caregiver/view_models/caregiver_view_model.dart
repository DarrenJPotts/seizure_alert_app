import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/watched_person_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/caregiver_service.dart';

class CaregiverViewModel extends GetxController {
  CaregiverViewModel(this._caregiverService);

  final CaregiverService _caregiverService;

  final RxList<WatchedPersonDto> people = <WatchedPersonDto>[].obs;
  final RxList<WatchActivityDto> recentActivity = <WatchActivityDto>[].obs;
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;

  @override
  void onInit() {
    super.onInit();
    loadPeopleIWatch();
  }

  Future<void> loadPeopleIWatch({bool forceRefresh = false}) async {
    if (screenState.value != GenericScreenStates.loaded) {
      screenState.value = GenericScreenStates.loading;
    }

    final result = await _caregiverService.getPeopleIWatch(forceRefresh: forceRefresh);
    if (!result.isSuccess || result.data == null) {
      if (people.isEmpty) screenState.value = GenericScreenStates.error;
      return;
    }

    people.value = result.data!.people;
    recentActivity.value = result.data!.recentActivity;
    screenState.value = people.isEmpty ? GenericScreenStates.empty : GenericScreenStates.loaded;
  }

  List<WatchedPersonDto> get sortedPeople {
    final List<WatchedPersonDto> sorted = people.toList();
    sorted.sort((WatchedPersonDto a, WatchedPersonDto b) => _urgency(a).compareTo(_urgency(b)));
    return sorted;
  }

  int _urgency(WatchedPersonDto person) => switch (person.status) {
    WatchedPersonStatus.sos => 0,
    WatchedPersonStatus.headsUp => 1,
    WatchedPersonStatus.monitoring => 2,
  };
}
