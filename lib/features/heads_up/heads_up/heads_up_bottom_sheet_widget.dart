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
  late final TextEditingController _minutes = TextEditingController(
    text: vm.selectedMinutes.value.toString(),
  );
  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  void _choose(int minutes) {
    HapticFeedback.selectionClick();
    vm.selectedMinutes.value = minutes;
    _minutes.text = minutes.toString();
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
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
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
                        selectedColor: Colors.black,
                        backgroundColor: Colors.white,
                        labelStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: !_custom && selectedMinutes == minutes
                                  ? Colors.white
                                  : Colors.black,
                            ),
                        showCheckmark: false,
                        onSelected: (_) => _choose(minutes),
                      ),
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: _custom,
                      selectedColor: Colors.black,
                      backgroundColor: Colors.white,
                      labelStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(
                            color: _custom ? Colors.white : Colors.black,
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
                Obx(
                  () => TextField(
                    controller: _minutes,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Check-in duration (minutes)',
                      helperText: '1 minute to 24 hours (1,440 minutes)',
                      errorText:
                          HeadsUpViewModel.isValidDuration(
                            vm.selectedMinutes.value,
                          )
                          ? null
                          : 'Enter 1 to 1,440 minutes.',
                    ),
                    onChanged: (value) =>
                        vm.selectedMinutes.value = int.tryParse(value) ?? 0,
                  ),
                ),
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
            padding: EdgeInsets.all(Dimensions.sixteen),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
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
                _Step(
                  number: '1',
                  text: 'Your circle is notified you\'re feeling off',
                ),
                _Step(
                  number: '2',
                  text: 'A countdown starts on your home screen',
                ),
                _Step(
                  number: '3',
                  text: 'Check in anytime to cancel the alert',
                ),
                _Step(
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
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: Dimensions.sixteen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: vm.isLoading.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Send Heads Up',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
          child: Center(
            child: Text(
              number,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
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
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
        ),
      ],
    );
  }
}
