import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/extensions/typed_extensions.dart';
import 'package:seizure_app/core/services/circle_invite_service.dart';
import 'package:seizure_app/core/services/alert_drill_service.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/home_widget_service.dart';
import 'package:seizure_app/core/constants/firebase_collection_keys.dart';

class ContactsViewModel extends GetxController {
  ContactsViewModel(
    this._firestoreService,
    this._circleInviteService,
    this._alertDrillService,
  );

  final FirestoreService _firestoreService;
  final CircleInviteService _circleInviteService;
  final AlertDrillService _alertDrillService;

  final RxList<ContactDto> contacts = <ContactDto>[].obs;
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;
  final RxnString invitingContactId = RxnString();
  final RxBool sendingTestAlert = false.obs;
  final RxnString lastTestSummary = RxnString();

  StreamSubscription<List<ContactDto>>? _contactsSub;
  Timer? _initialLoadTimer;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  void _init() {
    if (_uid.isEmpty) {
      screenState.value = GenericScreenStates.error;
      return;
    }

    screenState.value = GenericScreenStates.loading;
    _initialLoadTimer = Timer(const Duration(seconds: 10), () {
      if (screenState.value == GenericScreenStates.loading) {
        screenState.value = GenericScreenStates.error;
      }
    });
    _contactsSub = _firestoreService
        .watchContacts(_uid)
        .listen(
          (list) {
            _initialLoadTimer?.cancel();
            contacts.value = list;
            _circleInviteService.syncContacts(list);
            screenState.value = GenericScreenStates.loaded;
            if (Get.isRegistered<HomeWidgetService>()) {
              unawaited(
                Get.find<HomeWidgetService>().setSetupReady(
                  list.any((ContactDto contact) => contact.isPushReady),
                ),
              );
            }
          },
          onError: (_) {
            _initialLoadTimer?.cancel();
            screenState.value = GenericScreenStates.error;
          },
        );
  }

  Future<ContactDto?> addContact({
    required String name,
    required String phone,
    String? relation,
    bool notifyViaPush = true,
  }) async {
    final contact = ContactDto(
      id: _firestoreService.newDocumentId(FirebaseCollectionKeys.contacts),
      userId: _uid,
      name: name.trim(),
      phone: phone.trim(),
      relation: relation.trimNullable(),
      priority: contacts.length,

      notifyViaPush: notifyViaPush,
      createdAt: DateTime.now(),
    );
    final result = await _firestoreService.upsertContact(contact);
    return result.isSuccess ? contact : null;
  }

  Future<ResultDto<String>> createCircleInvite({
    required String contactId,
    bool regenerate = false,
  }) async {
    if (invitingContactId.value != null) {
      return ResultDto.failure(
        'An invite is already being created. Please wait.',
      );
    }
    invitingContactId.value = contactId;
    try {
      return await _circleInviteService.createCircleInvite(
        contactId: contactId,
        regenerate: regenerate,
      );
    } finally {
      invitingContactId.value = null;
    }
  }

  Future<ResultDto<AlertDrillResult>> sendTestAlert() async {
    if (sendingTestAlert.value) {
      return ResultDto.failure('A test alert is already being sent.');
    }

    sendingTestAlert.value = true;
    lastTestSummary.value = null;
    try {
      final ResultDto<AlertDrillResult> result = await _alertDrillService
          .send();
      final AlertDrillResult? drill = result.data;
      if (result.isSuccess && drill != null) {
        final String devices = drill.sentCount == 1 ? 'device' : 'devices';
        lastTestSummary.value =
            'Test sent to ${drill.sentCount} caregiver $devices.';
      }
      return result;
    } finally {
      sendingTestAlert.value = false;
    }
  }

  Future<bool> updateContact({
    required ContactDto existing,
    required String name,
    required String phone,
    String? relation,
    bool notifyViaPush = true,
  }) async {
    final contact = ContactDto(
      id: existing.id,
      userId: existing.userId,
      name: name.trim(),
      phone: phone.trim(),
      relation: relation.trimNullable(),
      priority: existing.priority,
      notifyViaPush: notifyViaPush,
      createdAt: existing.createdAt,
      status: existing.status,
      linkedUid: existing.linkedUid,
      inviteStatus: existing.inviteStatus,
      inviteExpiresAt: existing.inviteExpiresAt,
    );
    final result = await _firestoreService.upsertContact(contact);
    if (result.isSuccess) _circleInviteService.invalidateContact(existing.id);
    return result.isSuccess;
  }

  Future<bool> deleteContact(String contactId) async {
    final result = await _firestoreService.deleteContact(contactId);
    if (result.isSuccess) _circleInviteService.invalidateContact(contactId);
    return result.isSuccess;
  }

  @override
  void onClose() {
    _initialLoadTimer?.cancel();
    _contactsSub?.cancel();
    super.onClose();
  }
}
