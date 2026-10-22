import 'package:flutter/material.dart';
import '../constants/dimensions.dart';
import '../themes/app_palette.dart';

class DurationStepperField extends StatelessWidget {
  const DurationStepperField({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.onChanged,
  });
  final String label;
  final int value;
  final int maxValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: Dimensions.four,
    children: [
      Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Container(
        padding: const EdgeInsets.all(Dimensions.four),
        decoration: BoxDecoration(
          color: context.cardSurface,
          border: context.designBorder,
          borderRadius: BorderRadius.circular(context.design.cardRadius),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final number = Expanded(
              child: Semantics(
                label: label,
                value: '$value',
                child: ExcludeSemantics(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value.toString().padLeft(2, '0'),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                ),
              ),
            );
            final increase = IconButton(
              tooltip: 'Increase ${label.toLowerCase()}',
              onPressed: value < maxValue ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add),
            );
            final decrease = IconButton(
              tooltip: 'Decrease ${label.toLowerCase()}',
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
            );
            // A single row halves the control height while retaining 48px taps.
            // Very narrow layouts keep a stacked fallback instead of tiny buttons.
            if (constraints.maxWidth >=
                Dimensions.fortyEight * 2 + Dimensions.twentyFour) {
              return Row(children: [decrease, number, increase]);
            }
            return Row(
              children: [
                number,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [increase, decrease],
                ),
              ],
            );
          },
        ),
      ),
    ],
  );
}
