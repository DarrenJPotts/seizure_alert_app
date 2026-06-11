import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';

class ContactsViewModel extends GetxController {
  ContactsViewModel(this._firestoreService);

  final FirestoreService _firestoreService;

  // ─── State ────────────────────────────────────────────────────────────────

  final RxList<ContactDto> contacts = <ContactDto>[].obs;
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;

  StreamSubscription<List<ContactDto>>? _contactsSub;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  void _init() {
    if (_uid.isEmpty) return;
    screenState.value = GenericScreenStates.loading;
    _contactsSub = _firestoreService.watchContacts(_uid).listen(
      (list) {
        contacts.value = list;
        screenState.value = GenericScreenStates.loaded;
      },
      onError: (_) => screenState.value = GenericScreenStates.error,
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<bool> addContact({
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
      relation: _clean(relation),
      priority: contacts.length, // append at end of priority order
      notifyViaSms: notifyViaSms,
      notifyViaPush: notifyViaPush,
      createdAt: DateTime.now(),
    );
    final result = await _firestoreService.upsertContact(contact);
    return result.isSuccess;
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
      relation: _clean(relation),
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

  String? _clean(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  void onClose() {
    _contactsSub?.cancel();
    super.onClose();
  }
}
