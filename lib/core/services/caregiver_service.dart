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

  WatchListDto? _cachedWatchList;
  DateTime? _cachedAt;
  static const _cacheTtl = Duration(seconds: 30);

  Future<ResultDto<WatchListDto>> getPeopleIWatch({bool forceRefresh = false}) async {
    final cachedAt = _cachedAt;
    if (!forceRefresh &&
        _cachedWatchList != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl) {
      return ResultDto.success(_cachedWatchList!);
    }

    try {
      final result = await _functions.httpsCallable('getPeopleIWatch').call();
      final data = Map<String, dynamic>.from(result.data as Map);
      final watchList = WatchListDto.fromMap(data);
      _cachedWatchList = watchList;
      _cachedAt = DateTime.now();
      return ResultDto.success(watchList);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  void invalidateWatchList() {
    _cachedWatchList = null;
    _cachedAt = null;
  }

  Future<ResultDto<AlertDetailDto>> getAlertDetail(String alertId) async {
    try {
      final result = await _functions.httpsCallable('getAlertDetail').call({'alertId': alertId});
      final data = Map<String, dynamic>.from(result.data as Map);
      return ResultDto.success(AlertDetailDto.fromMap(data));
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<ResultDto<void>> deleteMyData() async {
    try {
      await _functions.httpsCallable('deleteMyData').call();
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<ResultDto<void>> submitAlertResponse({
    required String alertId,
    bool? responding,
    String? note,
  }) async {
    try {
      await _functions.httpsCallable('submitAlertResponse').call(<String, dynamic>{
        'alertId': alertId,
        'responding': ?responding,
        'note': ?note,
      });
      return ResultDto.success(null);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }

  Future<ResultDto<bool>> nudgeResponder({required String alertId, required String targetResponderId}) async {
    try {
      final result = await _functions.httpsCallable('nudgeResponder').call({
        'alertId': alertId,
        'targetResponderId': targetResponderId,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return ResultDto.success(data['delivered'] as bool? ?? false);
    } catch (e) {
      return ResultDto.failure(e.toString());
    }
  }
}
