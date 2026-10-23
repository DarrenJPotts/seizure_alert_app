import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:seizure_app/core/dtos/cycle_tracking_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/core/services/seizure_report_service.dart';
import 'package:seizure_app/features/cycle/view_models/cycle_view_model.dart';
import 'package:seizure_app/features/medical_card/models/medical_card_data.dart';
import 'package:seizure_app/features/seizure_log/view_models/seizure_log_view_model.dart';

class _Delayed extends FirestoreService {
  _Delayed() : super(FakeFirebaseFirestore());
  final response = Completer<ResultDto<CycleTrackingDto>>();
  @override
  Future<ResultDto<CycleTrackingDto>> getCycleTracking(String uid) =>
      response.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeFirebaseFirestore db;
  late FirestoreService store;
  late CycleViewModel vm;
  final today = DateTime(2026, 10, 23);
  CycleEntryDto entry({
    String id = 'period',
    int start = 15,
    int? end = 19,
    CycleFlow flow = CycleFlow.medium,
    String notes = 'Private cycle note',
  }) => CycleEntryDto(
    id: id,
    start: DateTime(2026, 10, start),
    end: end == null ? null : DateTime(2026, 10, end),
    flow: flow,
    symptoms: 'Cramps',
    notes: notes,
  );
  setUp(() async {
    Get.testMode = true;
    db = FakeFirebaseFirestore();
    await db
        .collection('users')
        .doc('owner')
        .set(
          UserDto(
            uid: 'owner',
            email: 'sample@example.test',
            displayName: 'Alex Morgan',
          ).toMap(),
        );
    store = FirestoreService(db);
    vm = CycleViewModel(store, currentUid: () => 'owner', clock: () => today);
    await vm.load();
  });
  tearDown(() {
    vm.onClose();
    Get.reset();
  });
  test(
    'cycle diary is disabled by default and preserves separate profile fields',
    () async {
      expect(vm.data.value.enabled, isFalse);
      expect(await vm.save(entry()), isFalse);
      expect(await vm.setEnabled(true), isTrue);
      expect(await vm.save(entry()), isTrue);
      await store.updateProfileFields('owner', {'displayName': 'Updated name'});
      await store.updateSafetyPlan('owner', {
        'seizureActionPlan': 'Stay nearby',
      });
      await store.updateReminders('owner', (current) => current);
      final saved = (await db.collection('users').doc('owner').get()).data()!;
      expect((saved['cycleTracking'] as Map)['entries'], hasLength(1));
      expect(saved['displayName'], 'Updated name');
      expect(saved['seizureActionPlan'], 'Stay nearby');
      final user = UserDto.fromMap(saved);
      expect(user.toMap().containsKey('cycleTracking'), isFalse);
      expect(
        MedicalCardData(user).shareText(MedicalCardField.values.toSet()),
        isNot(contains('Private cycle note')),
      );
    },
  );
  test(
    'edit, disable, reload, remove and delete-all preserve intended data',
    () async {
      await vm.setEnabled(true);
      await vm.save(entry());
      await vm.save(entry(end: 20, notes: 'Corrected entry'));
      expect(vm.data.value.entries.single.end!.day, 20);
      await vm.setEnabled(false);
      await vm.load();
      expect(vm.data.value.entries.single.notes, 'Corrected entry');
      expect(await vm.save(entry(id: 'other', start: 22, end: 23)), isFalse);
      await vm.setEnabled(true);
      await vm.remove('period');
      expect(vm.data.value.entries, isEmpty);
      await vm.save(entry());
      await vm.deleteAll();
      await vm.load();
      expect(vm.data.value.entries, isEmpty);
    },
  );
  test(
    'calendar boundaries and invalid or overlapping entries are handled',
    () async {
      await vm.setEnabled(true);
      expect(entry().contains(DateTime(2026, 10, 15), today), isTrue);
      expect(entry().contains(DateTime(2026, 10, 19), today), isTrue);
      expect(entry().contains(DateTime(2026, 10, 20), today), isFalse);
      expect(entry(end: null).contains(today, today), isTrue);
      expect(
        entry(end: null).contains(today.add(const Duration(days: 1)), today),
        isFalse,
      );
      expect(await vm.save(entry(start: 24, end: 25)), isFalse);
      expect(await vm.save(entry(start: 20, end: 19)), isFalse);
      expect(await vm.save(entry(notes: 'x' * 501)), isFalse);
      expect(await vm.save(entry()), isTrue);
      expect(await vm.save(entry(id: 'overlap', start: 18, end: 20)), isFalse);
      expect(vm.error.value, contains('overlap'));
      expect(
        await vm.save(
          entry(
            id: 'irregular',
            start: 22,
            end: null,
            flow: CycleFlow.spotting,
          ),
        ),
        isTrue,
      );
      expect(vm.data.value.entries.length, 2);
      expect(CycleEntryDto.fromMap(entry().toMap()).toMap(), entry().toMap());
    },
  );
  test('stale edits cannot overwrite additions from another device', () async {
    await vm.setEnabled(true);
    final second = CycleViewModel(
      store,
      currentUid: () => 'owner',
      clock: () => today,
    );
    await second.load();
    await vm.save(entry());
    expect(await second.save(entry(id: 'second', start: 22, end: 23)), isFalse);
    await second.load();
    expect(second.data.value.entries.single.id, 'period');
    expect(await second.save(entry(id: 'second', start: 22, end: 23)), isTrue);
    await vm.load();
    expect(vm.data.value.entries.length, 2);
    second.onClose();
  });
  test(
    'loading failure and account changes do not expose prior-cycle results',
    () async {
      final delayed = _Delayed();
      String uid = 'owner';
      final controller = CycleViewModel(delayed, currentUid: () => uid);
      final pending = controller.load();
      uid = 'other';
      delayed.response.complete(
        ResultDto.success(CycleTrackingDto(enabled: true, entries: [entry()])),
      );
      await pending;
      expect(controller.data.value.entries, isEmpty);
      controller.onClose();
      final unauthenticated = CycleViewModel(store, currentUid: () => null);
      await unauthenticated.load();
      expect(unauthenticated.loading.value, isFalse);
      expect(unauthenticated.error.value, contains('Sign in'));
      unauthenticated.onClose();
    },
  );
  test('disposed controller ignores late cycle data', () async {
    final delayed = _Delayed();
    final controller = Get.put(
      CycleViewModel(delayed, currentUid: () => 'owner'),
    );
    await Get.delete<CycleViewModel>();
    delayed.response.complete(
      ResultDto.success(CycleTrackingDto(enabled: true, entries: [entry()])),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.data.value.entries, isEmpty);
  });
  test(
    'default report excludes cycle files; opt-in adds cycle CSV and PDF section',
    () async {
      for (final include in [false, true]) {
        ShareParams? shared;
        final report = SeizureReportService(
          share: (params) async {
            shared = params;
            return const ShareResult('', ShareResultStatus.success);
          },
        );
        final result = await report.shareClinicalReport(
          user: UserDto(
            uid: 'owner',
            email: 'sample@example.test',
            displayName: 'Alex Morgan',
          ),
          logs: [
            SeizureLogDto(
              id: 'event',
              userId: 'owner',
              occurredAt: DateTime(2026, 10, 16, 9),
              seizureType: 'Tonic',
              durationSeconds: 45,
            ),
          ],
          includeCycleData: include,
          cycleEntries: [entry(notes: '=PRIVATE()')],
        );
        expect(result.isSuccess, isTrue);
        expect(shared!.files, hasLength(include ? 3 : 2));
        expect(
          utf8.decode(await shared!.files!.first.readAsBytes()),
          isNot(contains('PRIVATE')),
        );
        if (include) {
          expect(
            utf8.decode(await shared!.files!.last.readAsBytes()),
            contains("'=PRIVATE()"),
          );
        }
        if (const bool.fromEnvironment('CYCLE_REPORT_PREVIEW')) {
          await Directory('.buildlog').create(recursive: true);
          await File(
            '.buildlog/cycle-report-${include ? 'included' : 'excluded'}.pdf',
          ).writeAsBytes(await shared!.files![1].readAsBytes());
        }
      }
    },
  );
  test(
    'report view model refuses cycle inclusion when disabled and defaults to no cycle data',
    () async {
      final requests = <ShareParams>[];
      final report = SeizureReportService(
        share: (params) async {
          requests.add(params);
          return const ShareResult('', ShareResultStatus.success);
        },
      );
      final logVm = SeizureLogViewModel(
        store,
        currentUid: () => 'owner',
        reportService: report,
      );
      expect(
        await logVm.shareReport(includeCycleData: true),
        contains('Cycle data could not'),
      );
      expect(requests, isEmpty);
      await vm.setEnabled(true);
      await vm.save(entry());
      expect(await logVm.shareReport(), isNull);
      expect(requests.last.files, hasLength(2));
      expect(await logVm.shareReport(includeCycleData: true), isNull);
      expect(requests.last.files, hasLength(3));
      logVm.onClose();
    },
  );
}
