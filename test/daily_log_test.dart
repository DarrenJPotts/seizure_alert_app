import 'dart:async';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/dtos/daily_log_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/features/daily_log/view_models/daily_log_view_model.dart';

class DelayedStore extends FirestoreService {
  DelayedStore() : super(FakeFirebaseFirestore());
  final requests = <String, Completer<ResultDto<DailyLogDto?>>>{};
  @override
  Future<ResultDto<DailyLogDto?>> getDailyLog(String uid, DateTime day) =>
      (requests[dailyDateKey(day)] = Completer<ResultDto<DailyLogDto?>>())
          .future;
}

void main() {
  final day = DateTime(2026, 10, 20);
  late FakeFirebaseFirestore db;
  late FirestoreService store;
  setUp(() async {
    db = FakeFirebaseFirestore();
    store = FirestoreService(db);
    await db.collection('users').doc('owner').set({
      'cycleTracking': {'enabled': true},
      'displayName': 'Fictional',
    });
  });
  test(
    'civil dates and missing values round-trip without normal assumptions',
    () {
      expect(dailyDateKey(DateTime(2026, 1, 2, 23)), '2026-01-02');
      final dto = DailyLogDto(
        date: day,
        mood: 'low',
      ).saved(1, DateTime.utc(2026, 10, 21));
      final copy = DailyLogDto.fromMap(dto.toMap());
      expect(copy.sleepMinutes, isNull);
      expect(copy.noSeizuresReported, false);
      expect(copy.mood, 'low');
      expect(copy.updatedAt, dto.updatedAt);
      expect(
        () => DailyLogDto.fromMap({...dto.toMap(), 'date': '2026-02-30'}),
        throwsFormatException,
      );
    },
  );
  test('bounds reject invalid dates, fields and empty records', () {
    expect(DailyLogDto(date: day).validate(day), isNotNull);
    expect(
      DailyLogDto(date: day, noSeizuresReported: true).validate(day),
      isNull,
    );
    expect(DailyLogDto(date: day, sleepMinutes: 1440).validate(day), isNull);
    for (final dto in [
      DailyLogDto(date: day, sleepMinutes: -1),
      DailyLogDto(date: day, sleepMinutes: 1441),
      DailyLogDto(date: day, mood: 'excellent'),
      DailyLogDto(date: DateTime(2026, 10, 21), mood: 'low'),
      DailyLogDto(date: day, notes: 'x' * 501),
    ]) {
      expect(dto.validate(day), isNotNull);
    }
  });
  test(
    'dated records stay separate from profile, seizure and cycle data',
    () async {
      final result = await store.saveDailyLog(
        'owner',
        DailyLogDto(date: day, sleepMinutes: 450, mood: 'neutral'),
      );
      expect(result.isSuccess, true);
      expect(result.data!.revision, 1);
      expect((await store.getDailyLog('owner', day)).data!.sleepMinutes, 450);
      expect(
        (await db.collection('users').doc('owner').get())
            .data()!['cycleTracking'],
        {'enabled': true},
      );
      expect(
        (await store.getDailyLog('owner', DateTime(2026, 10, 19))).data,
        isNull,
      );
      expect((await store.getDailyLog('other', day)).data, isNull);
      expect((await store.getDailyLogs('owner', day, day)).data, hasLength(1));
    },
  );
  test(
    'stale create update and delete cannot overwrite a newer entry',
    () async {
      final first = (await store.saveDailyLog(
        'owner',
        DailyLogDto(date: day, mood: 'low'),
      )).data!;
      expect(
        (await store.saveDailyLog(
          'owner',
          DailyLogDto(date: day, mood: 'good'),
        )).isSuccess,
        false,
      );
      final next = (await store.saveDailyLog(
        'owner',
        DailyLogDto(date: day, mood: 'good'),
        expected: first,
      )).data!;
      expect(next.revision, 2);
      expect(
        (await store.saveDailyLog(
          'owner',
          DailyLogDto(date: day, mood: 'low'),
          expected: first,
        )).isSuccess,
        false,
      );
      expect((await store.deleteDailyLog('owner', first)).isSuccess, false);
      expect((await store.deleteDailyLog('owner', next)).isSuccess, true);
      expect((await store.getDailyLog('owner', day)).data, isNull);
    },
  );
  test('missing profile and empty uid prevent writes', () async {
    expect(
      (await store.saveDailyLog(
        '',
        DailyLogDto(date: day, mood: 'low'),
      )).isSuccess,
      false,
    );
    expect(
      (await store.saveDailyLog(
        'missing',
        DailyLogDto(date: day, mood: 'low'),
      )).isSuccess,
      false,
    );
  });
  test(
    'date guard preserves selection and selected-date save/remove works',
    () async {
      final vm = DailyLogViewModel(
        store,
        currentUid: () => 'owner',
        clock: () => day,
      );
      await vm.load();
      vm.confirmDateChange = () async => false;
      expect(await vm.selectDate(DateTime(2026, 10, 19)), false);
      expect(vm.selectedDate.value, day);
      vm.confirmDateChange = () async => true;
      expect(await vm.selectDate(DateTime(2026, 10, 19)), true);
      expect(await vm.selectDate(DateTime(2026, 10, 21)), false);
      expect(
        await vm.save(
          DailyLogDto(date: vm.selectedDate.value, stress: 'high'),
          null,
        ),
        true,
      );
      expect(await vm.remove(vm.entry.value!), true);
      vm.onClose();
    },
  );
  test(
    'late responses cannot replace another date or another account',
    () async {
      final delayed = DelayedStore();
      var uid = 'owner';
      final vm = DailyLogViewModel(
        delayed,
        currentUid: () => uid,
        clock: () => day,
      );
      final first = vm.load();
      final second = vm.selectDate(DateTime(2026, 10, 19));
      await Future<void>.delayed(Duration.zero);
      delayed.requests['2026-10-19']!.complete(
        ResultDto.success(
          DailyLogDto(date: DateTime(2026, 10, 19), mood: 'good'),
        ),
      );
      await second;
      delayed.requests['2026-10-20']!.complete(
        ResultDto.success(DailyLogDto(date: day, mood: 'low')),
      );
      await first;
      expect(vm.entry.value!.mood, 'good');
      final third = vm.load();
      uid = 'other';
      delayed.requests['2026-10-19']!.complete(ResultDto.success(null));
      await third;
      expect(vm.entry.value!.mood, 'good');
      vm.onClose();
    },
  );
}
