import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/extensions/typed_extensions.dart';
import 'package:seizure_app/core/services/circle_invite_service.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';

class ContactsViewModel extends GetxController {
  ContactsViewModel(this._firestoreService, this._circleInviteService);

  final FirestoreService _firestoreService;
  final CircleInviteService _circleInviteService;

  /// `State`
  final RxList<ContactDto> contacts = <ContactDto>[].obs;
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;

  StreamSubscription<List<ContactDto>>? _contactsSub;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// `Lifecycle`
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
    _contactsSub = _firestoreService.watchContacts(_uid).listen((list) {
      contacts.value = list;
      screenState.value = GenericScreenStates.loaded;
    }, onError: (_) => screenState.value = GenericScreenStates.error);
  }

  /// `UI Logic`
  Future<ContactDto?> addContact({
    required String name,
    required String phone,
    String? relation,
    bool notifyViaSms = true,
    bool notifyViaPush = true,
  }) async {
    final contact = ContactDto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _uid,
      name: name.trim(),
      phone: phone.trim(),
      relation: relation.trimNullable(),
      priority: contacts.length,
      // append at end of priority order
      notifyViaSms: notifyViaSms,
      notifyViaPush: notifyViaPush,
      createdAt: DateTime.now(),
    );
    final result = await _firestoreService.upsertContact(contact);
    return result.isSuccess ? contact : null;
  }

  /// Checks whether [phone] belongs to a registered app user and, if so,
  /// sends them an in-app invite (gating [contactId] to pending until they
  /// accept) instead of relying on the SMS/WhatsApp share link.
  Future<SendInviteResult?> sendCircleInvite({required String contactId, required String phone}) async {
    final ResultDto<SendInviteResult> result = await _circleInviteService.sendCircleInvite(
      contactId: contactId,
      phone: phone,
    );
    return result.isSuccess ? result.data : null;
  }

  Future<bool> updateContact({
    required ContactDto existing,
    required String name,
    required String phone,
    String? relation,
    bool notifyViaSms = true,
    bool notifyViaPush = true,
  }) async {
    final contact = ContactDto(
      id: existing.id,
      userId: existing.userId,
      name: name.trim(),
      phone: phone.trim(),
      relation: relation.trimNullable(),
      priority: existing.priority,
      notifyViaSms: notifyViaSms,
      notifyViaPush: notifyViaPush,
      createdAt: existing.createdAt,
    );
    final result = await _firestoreService.upsertContact(contact);
    return result.isSuccess;
  }

  Future<bool> deleteContact(String contactId) async {
    final result = await _firestoreService.deleteContact(contactId);
    return result.isSuccess;
  }

  @override
  void onClose() {
    _contactsSub?.cancel();
    super.onClose();
  }
}
