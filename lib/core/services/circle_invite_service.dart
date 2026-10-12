import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';

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

  Future<ResultDto<String>> createCircleInvite({
    required String contactId,
    bool regenerate = false,
  }) async {
    try {
      final result = await _functions.httpsCallable('createCircleInvite').call({
        'contactId': contactId,
        'regenerate': regenerate,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return ResultDto.success(data['code'] as String);
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
