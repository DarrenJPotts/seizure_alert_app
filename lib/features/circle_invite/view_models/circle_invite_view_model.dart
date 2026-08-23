import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/invite_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/circle_invite_service.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';

class CircleInviteViewModel extends GetxController {
  CircleInviteViewModel(this._inviteId, this._circleInviteService, this._firestoreService);

  final String _inviteId;
  final CircleInviteService _circleInviteService;
  final FirestoreService _firestoreService;

  final Rxn<InviteDto> invite = Rxn<InviteDto>();
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;
  final RxBool isResponding = false.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    if (_inviteId.isEmpty) {
      screenState.value = GenericScreenStates.error;
      return;
    }
    screenState.value = GenericScreenStates.loading;
    final result = await _firestoreService.getInvite(_inviteId);
    if (!result.isSuccess || result.data == null) {
      screenState.value = GenericScreenStates.error;
      return;
    }
    invite.value = result.data;
    screenState.value = GenericScreenStates.loaded;
  }

  Future<void> respond(bool accept) async {
    if (isResponding.value) return;
    isResponding.value = true;

    final result = await _circleInviteService.respondToInvite(
      inviteId: _inviteId,
      accept: accept,
    );

    isResponding.value = false;

    if (result.isSuccess) {
      Get.back();
      Get.snackbar(
        accept ? 'Invite accepted' : 'Invite declined',
        accept
            ? "You'll now be notified if they send an SOS or Heads Up."
            : "You won't be added to their circle.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Something went wrong',
        'Could not respond to the invite. Try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class CircleInviteBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as Map?;
    final inviteId = (args?['inviteId'] as String?) ?? Get.parameters['inviteId'] ?? '';
    Get.lazyPut(() => CircleInviteViewModel(
          inviteId,
          CircleInviteService.instance(),
          FirestoreService.instance(),
        ));
  }
}
