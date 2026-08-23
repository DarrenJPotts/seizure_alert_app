import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/alert_detail_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/dtos/watched_person_dto.dart';

class CaregiverService {
  CaregiverService(this._functions);

  static CaregiverService instance() => Get.isRegistered<CaregiverService>()
      ? Get.find<CaregiverService>()
      : Get.put(CaregiverService(FirebaseFunctions.instance));

  final FirebaseFunctions _functions;

  List<WatchedPersonDto>? _cachedPeople;
  DateTime? _cachedAt;
  static const _cacheTtl = Duration(seconds: 30);

  Future<ResultDto<List<WatchedPersonDto>>> getPeopleIWatch({bool forceRefresh = false}) async {
    final cachedAt = _cachedAt;
    if (!forceRefresh &&
        _cachedPeople != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl) {
      return ResultDto.success(_cachedPeople!);
    }

    try {
      final result = await _functions.httpsCallable('getPeopleIWatch').call();
      final data = Map<String, dynamic>.from(result.data as Map);
      final people = (data['people'] as List)
          .map((e) => WatchedPersonDto.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      _cachedPeople = people;
      _cachedAt = DateTime.now();
      return ResultDto.success(people);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<ResultDto<AlertDetailDto>> getAlertDetail(String alertId) async {
    try {
      final result = await _functions
          .httpsCallable('getAlertDetail')
          .call({'alertId': alertId});
      final data = Map<String, dynamic>.from(result.data as Map);
      return ResultDto.success(AlertDetailDto.fromMap(data));
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }
}
