import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';

typedef GridCell = ({DateTime date, bool hasSeizure, bool isFuture, bool isToday});

class HomeViewModel extends GetxController {
  HomeViewModel(this._firestoreService);

  final FirestoreService _firestoreService;

  // ─── State ────────────────────────────────────────────────────────────────

  final Rxn<UserDto> user = Rxn<UserDto>();
  final RxList<SeizureLogDto> seizureLogs = <SeizureLogDto>[].obs;
  final Rx<GenericScreenStates> screenState = GenericScreenStates.initial.obs;

  StreamSubscription<List<SeizureLogDto>>? _seizureLogsSub;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    if (_uid.isEmpty) return;
    screenState.value = GenericScreenStates.loading;

    final userResult = await _firestoreService.getUser(_uid);
    if (userResult.isSuccess) user.value = userResult.data;

    _seizureLogsSub = _firestoreService.watchSeizureLogs(_uid).listen(
      (list) {
        seizureLogs.value = list;
        screenState.value = GenericScreenStates.loaded;
      },
      onError: (_) => screenState.value = GenericScreenStates.error,
    );
  }

  // ─── Greeting ─────────────────────────────────────────────────────────────

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get firstName {
    final name =
        user.value?.displayName ?? FirebaseAuth.instance.currentUser?.displayName;
    if (name == null || name.trim().isEmpty) return '';
    return name.trim().split(' ').first;
  }

  // ─── Stats ────────────────────────────────────────────────────────────────

  /// Whole days since the most recent seizure, or null if no logs exist.
  int? get daysSinceLastSeizure {
    if (seizureLogs.isEmpty) return null;
    final today = _today;
    final last = seizureLogs.first.occurredAt;
    final lastNorm = DateTime(last.year, last.month, last.day);
    return today.difference(lastNorm).inDays;
  }

  int get last7DaysCount {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return seizureLogs.where((l) => l.occurredAt.isAfter(cutoff)).length;
  }

  int get thisMonthCount {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return seizureLogs.where((l) => !l.occurredAt.isBefore(monthStart)).length;
  }

  // ─── Activity grid ────────────────────────────────────────────────────────

  /// 28 cells — Monday 3 weeks ago through next Sunday (or today if mid-week).
  List<GridCell> get gridData {
    final today = _today;
    final start = _gridStart;
    return List.generate(28, (i) {
      final day = start.add(Duration(days: i));
      final isFuture = day.isAfter(today);
      final isToday = day == today;
      final hasSeizure = !isFuture && seizureLogs.any((l) {
        final logDay = DateTime(l.occurredAt.year, l.occurredAt.month, l.occurredAt.day);
        return logDay == day;
      });
      return (date: day, hasSeizure: hasSeizure, isFuture: isFuture, isToday: isToday);
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// The Monday that starts the 4-week grid (3 full weeks before this week's Monday).
  DateTime get _gridStart {
    final daysFromMonday = _today.weekday - 1;
    final thisMonday = _today.subtract(Duration(days: daysFromMonday));
    return thisMonday.subtract(const Duration(days: 21));
  }

  @override
  void onClose() {
    _seizureLogsSub?.cancel();
    super.onClose();
  }
}
