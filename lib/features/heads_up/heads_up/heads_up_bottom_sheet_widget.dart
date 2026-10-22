import 'package:seizure_app/core/widgets/duration_stepper_field.dart';
import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:seizure_app/features/heads_up/view_models/heads_up_view_model.dart';

class HeadsUpBottomSheet extends StatefulWidget {
  const HeadsUpBottomSheet({
    super.key,
    this.customDuration = false,
    this.viewModel,
  });
  final bool customDuration;
  final HeadsUpViewModel? viewModel;

  static Future<void> show({bool customDuration = false}) =>
      AppBottomSheet.show(
        context: Get.context!,
        builder: (_) => HeadsUpBottomSheet(customDuration: customDuration),
      );

  @override
  State<HeadsUpBottomSheet> createState() => _HeadsUpBottomSheetState();
}

class _HeadsUpBottomSheetState extends State<HeadsUpBottomSheet> {
  late final HeadsUpViewModel vm =
      widget.viewModel ?? HeadsUpViewModel.instance();
  late bool _custom =
      widget.customDuration ||
      !HeadsUpViewModel.windowOptions.contains(vm.selectedMinutes.value);
  void _choose(int minutes) {
    HapticFeedback.selectionClick();
    vm.selectedMinutes.value = minutes;
    setState(() => _custom = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Dimensions.twentyFour,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Dimensions.eight,
            children: [
              Text('Heads Up', style: Theme.of(context).textTheme.titleLarge),
              Text(
                'Let your circle know you\'re feeling off. If you don\'t check in, they\'ll be notified to reach out.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
              ),
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Dimensions.twelve,
            children: [
              Text(
                'Notify if no check-in within',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Obx(() {
                final selectedMinutes = vm.selectedMinutes.value;
                return Wrap(
                  spacing: Dimensions.eight,
                  runSpacing: Dimensions.eight,
                  children: [
                    for (final minutes in HeadsUpViewModel.windowOptions)
                      ChoiceChip(
                        label: Text(
                          minutes < 60 ? '$minutes min' : '${minutes ~/ 60} hr',
                        ),
                        selected: !_custom && selectedMinutes == minutes,
                        selectedColor: context.ink,
                        backgroundColor: context.paper,
                        labelStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: !_custom && selectedMinutes == minutes
                                  ? context.paper
                                  : context.ink,
                            ),
                        showCheckmark: false,
                        onSelected: (_) => _choose(minutes),
                      ),
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: _custom,
                      selectedColor: context.ink,
                      backgroundColor: context.paper,
                      labelStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(
                            color: _custom ? context.paper : context.ink,
                          ),
                      showCheckmark: false,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _custom = true);
                      },
                    ),
                  ],
                );
              }),
              if (_custom)
                Obx(() {
                  final total = vm.selectedMinutes.value;
                  final hours = (total ~/ 60).clamp(0, 24);
                  final minutes = hours == 24
                      ? 0
                      : total.remainder(60).clamp(0, 59);
                  final hourSelector = DurationStepperField(
                    key: const ValueKey('heads-up-hours'),
                    label: 'Hours',
                    value: hours,
                    maxValue: 24,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      vm.selectedMinutes.value =
                          value * 60 + (value == 24 ? 0 : minutes);
                    },
                  );
                  final minuteSelector = DurationStepperField(
                    key: const ValueKey('heads-up-minutes'),
                    label: 'Minutes',
                    value: minutes,
                    maxValue: hours == 24 ? 0 : 59,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      vm.selectedMinutes.value = hours * 60 + value;
                    },
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: Dimensions.twelve,
                    children: [
                      Row(
                        spacing: Dimensions.eight,
                        children: [
                          Expanded(child: hourSelector),
                          Text(
                            ':',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Expanded(child: minuteSelector),
                        ],
                      ),
                      Text(
                        total == 0
                            ? 'Select at least 1 minute.'
                            : '1 minute to 24 hours',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: total == 0
                              ? Theme.of(context).colorScheme.error
                              : context.secondaryInk,
                        ),
                      ),
                    ],
                  );
                }),
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Dimensions.twelve,
            children: [
              Text(
                'Add a note (optional)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextField(
                controller: vm.noteController,
                maxLines: 3,
                maxLength: 120,
                decoration: const InputDecoration(
                  hintText: 'e.g. Feeling an aura, heading home...',
                ),
              ),
            ],
          ),

          Container(
            padding: const EdgeInsets.all(Dimensions.sixteen),
            decoration: BoxDecoration(
              color: context.ink.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Dimensions.eight,
              children: [
                Text(
                  'What happens next',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const _Step(
                  number: '1',
                  text: 'Your circle is notified you\'re feeling off',
                ),
                const _Step(
                  number: '2',
                  text: 'A countdown starts on your home screen',
                ),
                const _Step(
                  number: '3',
                  text: 'Check in anytime to cancel the alert',
                ),
                const _Step(
                  number: '4',
                  text: 'If time runs out, your circle is told to reach out',
                ),
              ],
            ),
          ),

          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    vm.isLoading.value ||
                        !HeadsUpViewModel.isValidDuration(
                          vm.selectedMinutes.value,
                        )
                    ? null
                    : vm.startHeadsUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.ink,
                  foregroundColor: context.paper,
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.sixteen,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      context.design.cardRadius,
                    ),
                  ),
                ),
                child: vm.isLoading.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: context.paper,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Send Heads Up',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: context.paper,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(shape: BoxShape.circle, color: context.ink),
          child: Center(
            child: Text(
              number,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.paper,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
          ),
        ),
      ],
    );
  }
}
