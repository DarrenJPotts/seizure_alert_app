import 'package:seizure_app/core/dtos/cycle_tracking_dto.dart';
import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';

class SeizureCalendarSummary extends StatelessWidget {
  const SeizureCalendarSummary({
    super.key,
    required this.logs,
    this.cycleEntries = const [],
    this.month,
    this.today,
    this.onDaySelected,
    this.recordedDates = const [],
  });

  final List<SeizureLogDto> logs;
  final List<CycleEntryDto> cycleEntries;
  final DateTime? month;
  final DateTime? today;
  final ValueChanged<DateTime>? onDaySelected;
  final List<DateTime> recordedDates;

  @override
  Widget build(BuildContext context) {
    final DateTime now = month ?? today ?? DateTime.now();
    final DateTime monthStart = DateTime(now.year, now.month);
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final int leading = monthStart.weekday - 1;
    final Map<int, int> counts = <int, int>{};
    for (final SeizureLogDto log in logs) {
      final at = log.occurredAt.toLocal();
      if (at.year == now.year && at.month == now.month) {
        counts.update(at.day, (int value) => value + 1, ifAbsent: () => 1);
      }
    }
    final List<Widget> cells = <Widget>[
      for (int index = 0; index < leading; index += 1) const SizedBox.shrink(),
      for (int day = 1; day <= daysInMonth; day += 1)
        _SelectableDay(
          date: DateTime(now.year, now.month, day),
          today: today ?? DateTime.now(),
          onSelected: onDaySelected,
          recorded: recordedDates.any(
            (date) => cycleDate(date) == DateTime(now.year, now.month, day),
          ),
          child: _DayCell(
            day: day,
            count: counts[day] ?? 0,
            isToday:
                cycleDate(DateTime(now.year, now.month, day)) ==
                cycleDate(today ?? DateTime.now()),
            period: cycleEntries.any(
              (entry) => entry.contains(
                DateTime(now.year, now.month, day),
                today ?? DateTime.now(),
              ),
            ),
          ),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(Dimensions.sixteen),
      decoration: BoxDecoration(
        color: context.paper,
        border: context.designBorder,
        boxShadow: context.designShadows,
        borderRadius: BorderRadius.circular(context.design.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: Dimensions.twelve,
            runSpacing: Dimensions.eight,
            children: <Widget>[
              Text(
                _monthLabel(now),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${counts.values.fold<int>(0, (int a, int b) => a + b)} ${counts.values.fold<int>(0, (int a, int b) => a + b) == 1 ? 'event' : 'events'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.twelve),
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final width = scale > 1.3 || onDaySelected != null
                  ? ((onDaySelected == null
                                ? Dimensions.twentyFour
                                : Dimensions.fortyEight) *
                            scale *
                            7)
                        .clamp(constraints.maxWidth, double.infinity)
                        .toDouble()
                  : constraints.maxWidth;
              final grid = SizedBox(
                width: width,
                child: GridView.count(
                  crossAxisCount: 7,
                  childAspectRatio: onDaySelected == null ? 1 : 0.8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    for (final String day in <String>[
                      'M',
                      'T',
                      'W',
                      'T',
                      'F',
                      'S',
                      'S',
                    ])
                      Center(
                        child: Text(
                          day,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: context.secondaryInk),
                        ),
                      ),
                    ...cells,
                  ],
                ),
              );
              return scale > 1.3 || onDaySelected != null
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: grid,
                    )
                  : grid;
            },
          ),
          if (MediaQuery.textScalerOf(context).scale(1) > 1.3) ...[
            const SizedBox(height: Dimensions.eight),
            Text(
              'Swipe the calendar to see more days.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: Dimensions.twelve),
          if (cycleEntries.isNotEmpty) ...[
            Text(
              'Filled circle: recorded seizure. Underline: recorded period or spotting.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
            ),
            const SizedBox(height: Dimensions.twelve),
          ],
          _TrendLine(logs: logs),
        ],
      ),
    );
  }

  String _monthLabel(DateTime date) => <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][date.month - 1];
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.count,
    required this.isToday,
    this.period = false,
  });

  final int day;
  final int count;
  final bool isToday;
  final bool period;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Day $day, $count recorded events${period ? ', period or spotting recorded' : ''}',
    child: ExcludeSemantics(
      child: Stack(
        children: [
          Center(
            child: Container(
              width: MediaQuery.textScalerOf(context)
                  .scale(Dimensions.twenty)
                  .clamp(Dimensions.thirtyTwo, double.infinity)
                  .toDouble(),
              height: MediaQuery.textScalerOf(context)
                  .scale(Dimensions.twenty)
                  .clamp(Dimensions.thirtyTwo, double.infinity)
                  .toDouble(),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: count > 0 ? context.ink : Colors.transparent,
                border: isToday && count == 0
                    ? Border.all(color: context.ink)
                    : null,
              ),
              child: Text(
                '$day',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: count > 0 ? context.paper : context.secondaryInk,
                  fontWeight: count > 0 ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ),
          if (period)
            Positioned(
              bottom: 0,
              left: Dimensions.eight,
              right: Dimensions.eight,
              child: Container(height: Dimensions.three, color: context.ink),
            ),
        ],
      ),
    ),
  );
}

class _TrendLine extends StatelessWidget {
  const _TrendLine({required this.logs});

  final List<SeizureLogDto> logs;

  @override
  Widget build(BuildContext context) {
    final List<SeizureLogDto> recent = logs
        .where(
          (SeizureLogDto log) => log.occurredAt.isAfter(
            DateTime.now().subtract(const Duration(days: 90)),
          ),
        )
        .toList();
    final List<int> durations = recent
        .map((SeizureLogDto log) => log.durationSeconds)
        .whereType<int>()
        .toList();
    final int average = durations.isEmpty
        ? 0
        : durations.fold<int>(0, (int a, int b) => a + b) ~/ durations.length;
    final int rescueCount = recent
        .where((SeizureLogDto log) => log.rescueMedicationUsed)
        .length;
    return Row(
      children: <Widget>[
        Expanded(
          child: _Metric(label: '90 days', value: '${recent.length}'),
        ),
        Expanded(
          child: _Metric(
            label: 'Avg duration',
            value: average == 0 ? '—' : _duration(average),
          ),
        ),
        Expanded(
          child: _Metric(label: 'Rescue med', value: '$rescueCount'),
        ),
      ],
    );
  }

  String _duration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainder = seconds % 60;
    if (minutes == 0) return '${remainder}s';
    return remainder == 0 ? '${minutes}m' : '${minutes}m ${remainder}s';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: Dimensions.two),
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: context.secondaryInk),
      ),
    ],
  );
}

class _SelectableDay extends StatelessWidget {
  const _SelectableDay({
    required this.date,
    required this.today,
    required this.onSelected,
    required this.recorded,
    required this.child,
  });
  final DateTime date, today;
  final ValueChanged<DateTime>? onSelected;
  final bool recorded;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Expanded(child: child),
        SizedBox(
          height: MediaQuery.textScalerOf(context).scale(Dimensions.twelve),
          child: recorded
              ? Center(
                  child: Text(
                    '•',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                )
              : null,
        ),
      ],
    );
    if (onSelected == null) {
      return child;
    }
    return Semantics(
      label:
          '${date.year}-${date.month}-${date.day}${recorded ? ', daily check-in recorded' : ''}',
      button: true,
      child: InkWell(
        onTap: cycleDate(date).isAfter(cycleDate(today))
            ? null
            : () => onSelected!(date),
        child: content,
      ),
    );
  }
}
