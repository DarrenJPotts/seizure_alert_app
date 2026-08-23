import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/home/view_models/home_view_model.dart';

class ActivityGrid extends StatelessWidget {
  const ActivityGrid({super.key, required this.cells});

  final List<GridCell> cells;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activity', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: Dimensions.twelve),
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.black38,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        SizedBox(height: Dimensions.eight),
        Column(
          spacing: 4,
          children: List.generate(4, (week) {
            return Row(
              spacing: 4,
              children: List.generate(7, (day) {
                final cell = cells[week * 7 + day];
                return Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _GridCell(cell: cell),
                  ),
                );
              }),
            );
          }),
        ),
        SizedBox(height: Dimensions.twelve),
        Row(
          spacing: Dimensions.eight,
          children: [
            _LegendDot(color: Colors.black),
            Text(
              'Seizure',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.black54),
            ),
            SizedBox(width: Dimensions.four),
            _LegendDot(color: Colors.black.withValues(alpha: 0.08)),
            Text(
              'Seizure-free',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({required this.cell});

  final GridCell cell;

  @override
  Widget build(BuildContext context) {
    if (cell.isFuture) {
      return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)));
    }

    final color = cell.hasSeizure
        ? Colors.black
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: cell.isToday
            ? Border.all(color: Colors.black, width: 1.5)
            : null,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.black12),
        ),
      );
}
