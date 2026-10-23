import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/dtos/daily_log_dto.dart';
import '../../../core/themes/app_palette.dart';

DateTime dailyWeekStart(DateTime date) =>
    DateTime(date.year, date.month, date.day - date.weekday + 1);

/// Each page contains one Monday–Sunday week, including across month boundaries.
class DailyWeekSelector extends StatefulWidget {
  const DailyWeekSelector({
    super.key,
    required this.selectedDate,
    required this.today,
    required this.onSelect,
    this.enabled = true,
  });
  final DateTime selectedDate, today;
  final Future<bool> Function(DateTime) onSelect;
  final bool enabled;
  @override
  State<DailyWeekSelector> createState() => _DailyWeekSelectorState();
}

class _DailyWeekSelectorState extends State<DailyWeekSelector> {
  static final _epoch = DateTime.utc(1900);
  late final PageController _pages;
  bool _changing = false;
  int _index(DateTime date) {
    final start = dailyWeekStart(date);
    return DateTime.utc(
          start.year,
          start.month,
          start.day,
        ).difference(_epoch).inDays ~/
        7;
  }

  DateTime _start(int index) {
    final utc = _epoch.add(Duration(days: index * 7));
    return DateTime(utc.year, utc.month, utc.day);
  }

  @override
  void initState() {
    super.initState();
    _pages = PageController(initialPage: _index(widget.selectedDate));
  }

  @override
  void didUpdateWidget(covariant DailyWeekSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index(oldWidget.selectedDate) != _index(widget.selectedDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    }
  }

  void _sync() {
    if (!mounted || !_pages.hasClients) {
      return;
    }
    final index = _index(widget.selectedDate);
    if ((_pages.page ?? index).round() != index) {
      _pages.jumpToPage(index);
    }
  }

  Future<void> _selectWeek(int index) async {
    if (index == _index(widget.selectedDate)) {
      return;
    }
    if (_changing || !widget.enabled) {
      _sync();
      return;
    }
    final start = _start(index);
    var date = DateTime(
      start.year,
      start.month,
      start.day + widget.selectedDate.weekday - 1,
    );
    if (date.isAfter(dailyDate(widget.today))) {
      date = dailyDate(widget.today);
    }
    HapticFeedback.selectionClick();
    setState(() => _changing = true);
    try {
      await widget.onSelect(date);
    } finally {
      if (mounted) {
        setState(() => _changing = false);
        _sync();
      }
    }
  }

  Future<void> _selectDay(DateTime date) async {
    if (_changing || !widget.enabled) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _changing = true);
    try {
      await widget.onSelect(date);
    } finally {
      if (mounted) {
        setState(() => _changing = false);
        _sync();
      }
    }
  }

  void _move(int offset) {
    final page = _index(widget.selectedDate) + offset;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final start = dailyWeekStart(widget.selectedDate);
    final end = DateTime(start.year, start.month, start.day + 6);
    final active = widget.enabled && !_changing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous week',
              onPressed: active && _index(start) > 0 ? () => _move(-1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${localizations.formatShortDate(start)} – ${localizations.formatShortDate(end)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              tooltip: 'Next week',
              onPressed: active && _index(start) < _index(widget.today)
                  ? () => _move(1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.eight),
        LayoutBuilder(
          builder: (context, constraints) {
            final scaler = MediaQuery.textScalerOf(context);
            final labelStyle = Theme.of(context).textTheme.labelSmall!;
            final numberStyle = Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w700);
            Size measure(String value, TextStyle style) {
              final painter = TextPainter(
                text: TextSpan(text: value, style: style),
                textDirection: Directionality.of(context),
                textScaler: scaler,
              )..layout();
              return painter.size;
            }

            const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final labelWidth = names
                .map((name) => measure(name, labelStyle).width)
                .reduce(math.max);
            final minWidth = math.max(
              Dimensions.fortyEight,
              math.max(labelWidth, measure('28', numberStyle).width) +
                  Dimensions.sixteen,
            );
            final columns =
                ((constraints.maxWidth + Dimensions.four) /
                        (minWidth + Dimensions.four))
                    .floor()
                    .clamp(1, 7);
            final width =
                (constraints.maxWidth - Dimensions.four * (columns - 1)) /
                columns;
            final height = math.max(
              Dimensions.fortyEight,
              measure('Mon', labelStyle).height +
                  measure('28', numberStyle).height +
                  Dimensions.four +
                  Dimensions.twentyFour,
            );
            final rows = (7 / columns).ceil();
            return SizedBox(
              height: height * rows + Dimensions.four * (rows - 1),
              child: PageView.builder(
                key: const ValueKey('daily-week-pages'),
                controller: _pages,
                itemCount: _index(widget.today) + 1,
                physics: active
                    ? const PageScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                onPageChanged: _selectWeek,
                itemBuilder: (context, index) {
                  final week = _start(index);
                  return Wrap(
                    spacing: Dimensions.four,
                    runSpacing: Dimensions.four,
                    children: [
                      for (var offset = 0; offset < 7; offset++)
                        Builder(
                          builder: (context) {
                            final date = DateTime(
                              week.year,
                              week.month,
                              week.day + offset,
                            );
                            final selected =
                                dailyDate(widget.selectedDate) == date;
                            final allowed =
                                active &&
                                !date.isAfter(dailyDate(widget.today));
                            return Semantics(
                              button: true,
                              selected: selected,
                              enabled: allowed,
                              label: localizations.formatFullDate(date),
                              child: SizedBox(
                                width: width,
                                height: height,
                                child: Material(
                                  color: selected
                                      ? context.ink
                                      : context.cardSurface,
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.twelve,
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.twelve,
                                    ),
                                    onTap: allowed
                                        ? () => _selectDay(date)
                                        : null,
                                    child: Center(
                                      child: ExcludeSemantics(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              names[offset],
                                              style: labelStyle.copyWith(
                                                color: selected
                                                    ? context.paper
                                                    : context.secondaryInk,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: Dimensions.four,
                                            ),
                                            Text(
                                              '${date.day}',
                                              style: numberStyle.copyWith(
                                                color: selected
                                                    ? context.paper
                                                    : context.ink.withValues(
                                                        alpha: allowed
                                                            ? 1
                                                            : 0.38,
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
