import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';

class SendInviteResult {
  SendInviteResult({required this.isRegisteredUser, this.inviteId});

  final bool isRegisteredUser;
  final String? inviteId;
}

class CircleInviteService {
  CircleInviteService(this._functions);

  static CircleInviteService instance() => Get.isRegistered<CircleInviteService>()
      ? Get.find<CircleInviteService>()
      : Get.put(CircleInviteService(FirebaseFunctions.instance));

  final FirebaseFunctions _functions;

  Future<ResultDto<SendInviteResult>> sendCircleInvite({
    required String contactId,
    required String phone,
  }) async {
    try {
      final result = await _functions.httpsCallable('sendCircleInvite').call({
        'contactId': contactId,
        'phone': phone,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return ResultDto.success(SendInviteResult(
        isRegisteredUser: data['isRegisteredUser'] as bool,
        inviteId: data['inviteId'] as String?,
      ));
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<ResultDto<String>> respondToInvite({
    required String inviteId,
    required bool accept,
  }) async {
    try {
      final result = await _functions.httpsCallable('respondToInvite').call({
        'inviteId': inviteId,
        'accept': accept,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return ResultDto.success(data['status'] as String);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }
}
