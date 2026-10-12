import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';

class SeizureCalendarSummary extends StatelessWidget {
  const SeizureCalendarSummary({super.key, required this.logs});

  final List<SeizureLogDto> logs;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime monthStart = DateTime(now.year, now.month);
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final int leading = monthStart.weekday - 1;
    final Map<int, int> counts = <int, int>{};
    for (final SeizureLogDto log in logs) {
      if (log.occurredAt.year == now.year &&
          log.occurredAt.month == now.month) {
        counts.update(
          log.occurredAt.day,
          (int value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    final List<Widget> cells = <Widget>[
      for (int index = 0; index < leading; index += 1) const SizedBox.shrink(),
      for (int day = 1; day <= daysInMonth; day += 1)
        _DayCell(day: day, count: counts[day] ?? 0, isToday: day == now.day),
    ];

    return Container(
      padding: EdgeInsets.all(Dimensions.sixteen),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(Dimensions.twelve),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                _monthLabel(now),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${counts.values.fold<int>(0, (int a, int b) => a + b)} events',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
          ),
          SizedBox(height: Dimensions.twelve),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              for (final String day in const <String>[
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
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.black45),
                  ),
                ),
              ...cells,
            ],
          ),
          SizedBox(height: Dimensions.twelve),
          _TrendLine(logs: logs),
        ],
      ),
    );
  }

  String _monthLabel(DateTime date) => const <String>[
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
  });

  final int day;
  final int count;
  final bool isToday;

  @override
  Widget build(BuildContext context) => Semantics(
    label: count == 0 ? 'Day $day, no events' : 'Day $day, $count events',
    child: ExcludeSemantics(
      child: Center(
        child: Container(
          width: Dimensions.thirtyTwo,
          height: Dimensions.thirtyTwo,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: count > 0 ? Colors.black : Colors.transparent,
            border: isToday && count == 0
                ? Border.all(color: Colors.black)
                : null,
          ),
          child: Text(
            '$day',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: count > 0 ? Colors.white : Colors.black54,
              fontWeight: count > 0 ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
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
      SizedBox(height: Dimensions.two),
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: Colors.black45),
      ),
    ],
  );
}
