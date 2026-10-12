import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';

class AlertDrillResult {
  const AlertDrillResult({
    required this.recipientCount,
    required this.sentCount,
    required this.failedCount,
    required this.capped,
  });

  final int recipientCount;
  final int sentCount;
  final int failedCount;
  final bool capped;

  factory AlertDrillResult.fromMap(Map<String, dynamic> map) =>
      AlertDrillResult(
        recipientCount: (map['recipientCount'] as num?)?.toInt() ?? 0,
        sentCount: (map['sentCount'] as num?)?.toInt() ?? 0,
        failedCount: (map['failedCount'] as num?)?.toInt() ?? 0,
        capped: map['capped'] as bool? ?? false,
      );
}

class AlertDrillService {
  AlertDrillService(this._functions);

  static AlertDrillService instance() => Get.isRegistered<AlertDrillService>()
      ? Get.find<AlertDrillService>()
      : Get.put(AlertDrillService(FirebaseFunctions.instance));

  final FirebaseFunctions _functions;

  Future<ResultDto<AlertDrillResult>> send() async {
    try {
      final HttpsCallableResult<dynamic> response = await _functions
          .httpsCallable('sendCaregiverTestAlert')
          .call();
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.data as Map,
      );
      return ResultDto.success(AlertDrillResult.fromMap(data));
    } on FirebaseFunctionsException catch (error) {
      final String message = switch (error.code) {
        'resource-exhausted' => 'Wait before sending another test alert.',
        'failed-precondition' =>
          error.message ?? 'No connected caregivers are ready for alerts.',
        'unavailable' => 'Test alerts are temporarily unavailable.',
        _ => 'The test alert could not be sent.',
      };
      return ResultDto.failure(message);
    } catch (_) {
      return ResultDto.failure('The test alert could not be sent.');
    }
  }
}
