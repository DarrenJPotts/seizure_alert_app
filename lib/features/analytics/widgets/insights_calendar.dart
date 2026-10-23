import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/dtos/daily_log_dto.dart';
import '../../../core/dtos/seizure_log_dto.dart';
import '../../../core/themes/app_palette.dart';
import '../../cycle/view_models/cycle_view_model.dart';
import '../../daily_log/view_models/daily_log_view_model.dart';
import '../../root/root_view.dart';
import '../../seizure_log/widgets/seizure_calendar_summary.dart';

class InsightsCalendar extends StatefulWidget {
  const InsightsCalendar({super.key, required this.logs});
  final List<SeizureLogDto> logs;
  @override
  State<InsightsCalendar> createState() => _InsightsCalendarState();
}

class _InsightsCalendarState extends State<InsightsCalendar> {
  late DateTime month;
  late DateTime today;
  Stream<List<DailyLogDto>>? records;
  @override
  void initState() {
    super.initState();
    today = Get.isRegistered<DailyLogViewModel>()
        ? Get.find<DailyLogViewModel>().today
        : dailyDate(DateTime.now());
    month = DateTime(today.year, today.month);
    _watch();
  }

  void _watch() {
    if (Get.isRegistered<DailyLogViewModel>()) {
      final vm = Get.find<DailyLogViewModel>();
      records = vm.store.watchDailyLogs(
        vm.uid,
        month,
        DateTime(month.year, month.month + 1, 0),
      );
    }
  }

  void _move(int offset) {
    HapticFeedback.selectionClick();
    setState(() {
      month = DateTime(month.year, month.month + offset);
      _watch();
    });
  }

  Future<void> _open(DateTime date) async {
    HapticFeedback.selectionClick();
    if (!Get.isRegistered<DailyLogViewModel>() ||
        !Get.isRegistered<RootViewModel>()) {
      return;
    }
    final accepted = await Get.find<DailyLogViewModel>().selectDate(date);
    if (accepted && mounted) {
      Get.find<RootViewModel>().changePage(1);
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<DailyLogDto>>(
    stream: records,
    builder: (context, snapshot) {
      final entries = snapshot.connectionState == ConnectionState.waiting
          ? <DailyLogDto>[]
          : snapshot.data ?? <DailyLogDto>[];
      final sleep = entries.where((e) => e.sleepMinutes != null).toList();
      final daily = Get.isRegistered<DailyLogViewModel>();
      final canOpen = daily && Get.isRegistered<RootViewModel>();
      Widget calendar() => SeizureCalendarSummary(
        logs: widget.logs,
        month: month,
        today: today,
        recordedDates: entries.map((e) => e.date).toList(),
        onDaySelected: canOpen ? _open : null,
        cycleEntries:
            Get.isRegistered<CycleViewModel>() &&
                Get.find<CycleViewModel>().data.value.enabled &&
                Get.find<CycleViewModel>().error.value == null
            ? Get.find<CycleViewModel>().data.value.entries
            : [],
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: month.year <= 1900 && month.month == 1
                    ? null
                    : () => _move(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${month.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed:
                    month.year == today.year && month.month == today.month
                    ? null
                    : () => _move(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          if (Get.isRegistered<CycleViewModel>()) Obx(calendar) else calendar(),
          const SizedBox(height: Dimensions.twelve),
          if (canOpen)
            const Text(
              'Tap a date to open Daily log. A dot marks a saved daily check-in. Swipe the calendar to see more days.',
            ),
          if (daily) ...[
            const SizedBox(height: Dimensions.twentyFour),
            Text(
              'Daily check-ins · this month',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Dimensions.eight),
            if (snapshot.hasError)
              const Text(
                'Could not load daily check-ins. Reopen Insights to try again.',
              )
            else if (snapshot.connectionState == ConnectionState.waiting)
              const LinearProgressIndicator()
            else ...[
              Text(
                '${entries.length} ${entries.length == 1 ? 'day' : 'days'} recorded. Unrecorded days are excluded.',
              ),
              if (sleep.isNotEmpty)
                Text(
                  'Average sleep: ${(sleep.fold<int>(0, (sum, e) => sum + e.sleepMinutes!) / sleep.length / 60).toStringAsFixed(1)} hours from ${sleep.length} recorded ${sleep.length == 1 ? 'night' : 'nights'}.',
                ),
              for (final option in DailyLogDto.stresses.entries)
                if (entries.any((e) => e.stress == option.key))
                  Text(
                    '${option.value} stress: ${entries.where((e) => e.stress == option.key).length} ${entries.where((e) => e.stress == option.key).length == 1 ? 'day' : 'days'}.',
                  ),
              if (entries.any((e) => e.sideEffects.isNotEmpty))
                Text(
                  'Side effects noted on ${entries.where((e) => e.sideEffects.isNotEmpty).length} days.',
                ),
              const SizedBox(height: Dimensions.eight),
              Text(
                'These are descriptions of your entries. They do not identify causes or predict seizures.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
              ),
            ],
          ],
        ],
      );
    },
  );
}
