import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/helpers/invite_code_cache.dart';

class CircleInvitePreview {
  const CircleInvitePreview({
    required this.senderName,
    required this.contactName,
  });

  final String senderName;
  final String contactName;
}

class CircleInviteService {
  CircleInviteService(this._functions);

  static CircleInviteService instance() =>
      Get.isRegistered<CircleInviteService>()
      ? Get.find<CircleInviteService>()
      : Get.put(CircleInviteService(FirebaseFunctions.instance));

  final FirebaseFunctions _functions;
  final _codes = InviteCodeCache();
  int _cacheGeneration = 0;

  void clearCache() {
    _cacheGeneration++;
    _codes.clear();
  }

  void invalidateContact(String contactId) {
    _cacheGeneration++;
    _codes.invalidate(contactId);
  }

  void syncContacts(List<ContactDto> contacts) {
    _codes.selectOwner(FirebaseAuth.instance.currentUser?.uid);
    _codes.retainContacts(contacts.map((contact) => contact.id).toSet());
    for (final contact in contacts) {
      if (contact.linkedUid != null ||
          contact.inviteStatus == 'accepted' ||
          contact.inviteStatus == 'declined' ||
          (contact.inviteExpiresAt != null &&
              !contact.inviteExpiresAt!.isAfter(DateTime.now()))) {
        invalidateContact(contact.id);
      }
    }
  }

  Future<ResultDto<String>> createCircleInvite({
    required String contactId,
    bool regenerate = false,
  }) async {
    final owner = FirebaseAuth.instance.currentUser?.uid;
    _codes.selectOwner(owner);
    if (regenerate) invalidateContact(contactId);
    final cached = _codes.get(contactId);
    if (!regenerate && cached != null) return ResultDto.success(cached);
    final generation = _cacheGeneration;
    try {
      final result = await _functions.httpsCallable('createCircleInvite').call({
        'contactId': contactId,
        'regenerate': regenerate,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final code = data['code'] as String;
      final expiry = data['expiresAt'];
      if (generation == _cacheGeneration &&
          owner != null &&
          FirebaseAuth.instance.currentUser?.uid == owner &&
          expiry is num) {
        _codes.put(
          contactId,
          code,
          DateTime.fromMillisecondsSinceEpoch(expiry.toInt(), isUtc: true),
        );
      }
      return ResultDto.success(code);
    } on FirebaseFunctionsException catch (error) {
      final message = switch (error.code) {
        'unauthenticated' =>
          'The app could not be verified. Restart the app and try again.',
        'unavailable' || 'deadline-exceeded' =>
          'The invite service is temporarily unavailable. Check your connection and try again.',
        _ => 'The invite could not be created. Please try again.',
      };
      return ResultDto.failure(message);
    } catch (e) {
      return ResultDto.failure(
        'The invite could not be created. Please try again.',
      );
    }
  }

  Future<ResultDto<CircleInvitePreview>> previewCircleInvite({
    required String code,
  }) async {
    try {
      final result = await _functions.httpsCallable('previewCircleInvite').call(
        {'code': code},
      );
      final data = Map<String, dynamic>.from(result.data as Map);
      return ResultDto.success(
        CircleInvitePreview(
          senderName: data['senderName'] as String,
          contactName: data['contactName'] as String,
        ),
      );
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<ResultDto<String>> respondToCircleInvite({
    required String code,
    required bool accept,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('respondToCircleInvite')
          .call({'code': code, 'accept': accept});
      final data = Map<String, dynamic>.from(result.data as Map);
      return ResultDto.success(data['status'] as String);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }
}
