import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';

typedef GridCell = ({
  DateTime date,
  bool hasSeizure,
  bool isFuture,
  bool isToday,
});

class HomeViewModel extends GetxController {
  HomeViewModel(this._firestoreService);

  final FirestoreService _firestoreService;

  final Rxn<UserDto> user = Rxn<UserDto>();
  final RxList<SeizureLogDto> seizureLogs = <SeizureLogDto>[].obs;
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;

  StreamSubscription<List<SeizureLogDto>>? _seizureLogsSub;
  int _loadGeneration = 0;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> retry() => _init();

  Future<void> _init() async {
    final request = ++_loadGeneration;
    await _seizureLogsSub?.cancel();
    if (isClosed || request != _loadGeneration) return;
    final uid = _uid;
    if (_uid.isEmpty) {
      screenState.value = GenericScreenStates.error;
      return;
    }
    screenState.value = GenericScreenStates.loading;

    final userResult = await _firestoreService.getUser(uid);
    if (isClosed || request != _loadGeneration || _uid != uid) return;
    if (userResult.isSuccess) user.value = userResult.data;

    _seizureLogsSub = _firestoreService.watchSeizureLogs(uid).listen((list) {
      seizureLogs.value = list;
      screenState.value = GenericScreenStates.loaded;
    }, onError: (_) => screenState.value = GenericScreenStates.error);
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get firstName {
    final name =
        user.value?.displayName ??
        FirebaseAuth.instance.currentUser?.displayName;
    if (name == null || name.trim().isEmpty) return '';
    return name.trim().split(' ').first;
  }

  int? get daysSinceLastSeizure {
    if (seizureLogs.isEmpty) return null;
    final today = _today;
    final last = seizureLogs.first.occurredAt;
    // Compare calendar days in UTC: on a daylight-saving change a local day
    // is 23 or 25 hours long, and inDays on local midnights is then off by one.
    final DateTime todayUtc = DateTime.utc(today.year, today.month, today.day);
    final DateTime lastUtc = DateTime.utc(last.year, last.month, last.day);
    return todayUtc.difference(lastUtc).inDays;
  }

  int get last7DaysCount {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return seizureLogs.where((l) => l.occurredAt.isAfter(cutoff)).length;
  }

  int get thisMonthCount {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return seizureLogs
        .where(
          (l) =>
              !l.occurredAt.isBefore(monthStart) && !l.occurredAt.isAfter(now),
        )
        .length;
  }

  List<GridCell> get gridData {
    final today = _today;
    final start = _gridStart;
    return List.generate(28, (i) {
      // Calendar arithmetic: adding 24-hour Durations to local midnight
      // drifts to 23:00 or 01:00 after a daylight-saving change.
      final day = DateTime(start.year, start.month, start.day + i);
      final isFuture = day.isAfter(today);
      final isToday = day == today;
      final hasSeizure =
          !isFuture &&
          seizureLogs.any((l) {
            final logDay = DateTime(
              l.occurredAt.year,
              l.occurredAt.month,
              l.occurredAt.day,
            );
            return logDay == day;
          });
      return (
        date: day,
        hasSeizure: hasSeizure,
        isFuture: isFuture,
        isToday: isToday,
      );
    });
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _gridStart {
    final DateTime today = _today;
    final int daysFromMonday = today.weekday - 1;
    return DateTime(today.year, today.month, today.day - daysFromMonday - 21);
  }

  @override
  void onClose() {
    _seizureLogsSub?.cancel();
    super.onClose();
  }
}
