import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/snackbar_margin.dart';
import 'package:seizure_app/core/services/circle_invite_service.dart';

class CircleInviteViewModel extends GetxController {
  CircleInviteViewModel(this._circleInviteService);

  final CircleInviteService _circleInviteService;
  final TextEditingController codeController = TextEditingController();
  final Rxn<CircleInvitePreview> preview = Rxn<CircleInvitePreview>();
  final RxBool isLoading = false.obs;
  final RxBool isResponding = false.obs;
  final RxnString errorMessage = RxnString();

  Future<void> lookUpCode() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    preview.value = null;
    final result = await _circleInviteService.previewCircleInvite(
      code: codeController.text.trim(),
    );
    isLoading.value = false;
    if (result.isSuccess) {
      preview.value = result.data;
    } else {
      errorMessage.value = 'Code is invalid, expired, or already used.';
    }
  }

  Future<void> respond(bool accept) async {
    if (isResponding.value || preview.value == null) return;
    isResponding.value = true;
    final result = await _circleInviteService.respondToCircleInvite(
      code: codeController.text.trim(),
      accept: accept,
    );
    isResponding.value = false;
    if (result.isSuccess) {
      Get.back();
      Get.snackbar(
        accept ? 'Invite accepted' : 'Invite declined',
        accept
            ? "You'll now receive their alerts."
            : "You won't be added to their circle.",
        snackPosition: SnackPosition.BOTTOM,
        margin: snackbarMargin,
      );
    } else {
      errorMessage.value =
          'This code is no longer available. Ask them to send a new invite.';
      preview.value = null;
    }
  }

  @override
  void onClose() {
    codeController.dispose();
    super.onClose();
  }
}

class CircleInviteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CircleInviteViewModel(CircleInviteService.instance()));
  }
}
