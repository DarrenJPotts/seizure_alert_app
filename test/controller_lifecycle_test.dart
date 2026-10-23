import 'dart:async';
import 'dart:convert';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/features/safety_plan/view_models/safety_plan_view_model.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/alert_detail_dto.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/dtos/heads_up_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/services/caregiver_service.dart';
import 'package:seizure_app/features/caregiver/view_models/incoming_alert_view_model.dart';
import 'package:seizure_app/features/caregiver/view_models/responding_view_model.dart';
import 'package:seizure_app/features/heads_up/view_models/heads_up_view_model.dart';
import 'package:seizure_app/features/sos/view_models/sos_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fixtures.dart';

class _Functions extends Fake implements FirebaseFunctions {}

class _DelayedCaregiver extends CaregiverService {
  _DelayedCaregiver() : super(_Functions());
  final completion = Completer<ResultDto<AlertDetailDto>>();
  @override
  Future<ResultDto<AlertDetailDto>> getAlertDetail(String alertId) =>
      completion.future;
}

class _DelayedFirestore extends FirestoreService {
  _DelayedFirestore() : super(FakeFirebaseFirestore());
  final completion = Completer<ResultDto<UserDto>>();
  @override
  Future<ResultDto<UserDto>> getUser(
    String uid, {
    bool requireCompleteProfile = false,
  }) => completion.future;
}

void main() {
  tearDown(() => Get.reset());
  testWidgets('closing incoming alert during load does not restart ticker', (
    tester,
  ) async {
    final service = _DelayedCaregiver();
    final vm = Get.put(IncomingAlertViewModel('alert', service));
    await Get.delete<IncomingAlertViewModel>();
    service.completion.complete(ResultDto.success(Fixtures.alertDetail()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(vm.detail.value, isNull);
    expect(vm.elapsed.value, Duration.zero);
  });
  testWidgets(
    'closing responding screen during load does not restart polling',
    (tester) async {
      final service = _DelayedCaregiver();
      final vm = Get.put(RespondingViewModel('alert', service));
      await Get.delete<RespondingViewModel>();
      service.completion.complete(ResultDto.success(Fixtures.alertDetail()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 31));
      expect(vm.detail.value, isNull);
      expect(vm.elapsed.value, Duration.zero);
    },
  );
  testWidgets(
    'closing safety plan during load never touches disposed text controllers',
    (tester) async {
      final db = _DelayedFirestore();
      final vm = Get.put(SafetyPlanViewModel(db, currentUid: () => 'user'));
      await Get.delete<SafetyPlanViewModel>();
      db.completion.complete(ResultDto.success(Fixtures.user()));
      await tester.pump();
      expect(vm.hasLoadedPlan, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  for (final closeImmediately in [false, true]) {
    testWidgets(
      'cached alerts are ignored when ${closeImmediately ? 'controllers close during restore' : 'owned by another account'}',
      (tester) async {
        final now = DateTime.now();
        final owner = closeImmediately ? 'current' : 'other';
        SharedPreferences.setMockInitialValues({
          'active_sos': jsonEncode(
            AlertDto(
              id: 'sos',
              userId: owner,
              type: AlertType.sos,
              status: AlertStatus.sent,
              createdAt: now,
            ).toMap(),
          ),
          'active_heads_up': jsonEncode(
            HeadsUpDto(
              id: 'heads',
              userId: owner,
              createdAt: now,
              expiresAt: now.add(const Duration(hours: 1)),
              status: HeadsUpStatus.active,
            ).toMap(),
          ),
        });
        final sos = Get.put(SosViewModel(currentUid: () => 'current'));
        final heads = Get.put(HeadsUpViewModel(currentUid: () => 'current'));
        if (closeImmediately) {
          // onDelete marks the lifecycle closed synchronously before preference futures complete.
          sos.onDelete();
          heads.onDelete();
        }
        await tester.pump();
        expect(sos.activeSos.value, isNull);
        expect(heads.activeHeadsUp.value, isNull);
        await Get.delete<SosViewModel>();
        await Get.delete<HeadsUpViewModel>();
      },
    );
  }
}
