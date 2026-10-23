import 'wellbeing_face_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/dtos/daily_log_dto.dart';
import '../../../core/themes/app_palette.dart';
import '../view_models/daily_log_view_model.dart';

class DailyCheckInForm extends StatefulWidget {
  const DailyCheckInForm({
    super.key,
    required this.controller,
    required this.date,
    this.entry,
    required this.hasSeizures,
  });
  final DailyLogViewModel controller;
  final DateTime date;
  final DailyLogDto? entry;
  final bool hasSeizures;
  @override
  State<DailyCheckInForm> createState() => DailyCheckInFormState();
}

class DailyCheckInFormState extends State<DailyCheckInForm> {
  final sleep = TextEditingController();
  final effects = TextEditingController();
  final notes = TextEditingController();
  String? quality, mood, stress;
  bool none = false;
  bool dirty = false;
  DailyLogDto? expected;
  String? validation;
  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    expected = widget.entry;
    sleep.text = expected?.sleepMinutes == null
        ? ''
        : (expected!.sleepMinutes! / 60)
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'\.?0+$'), '');
    effects.text = expected?.sideEffects ?? '';
    notes.text = expected?.notes ?? '';
    quality = expected?.sleepQuality;
    mood = expected?.mood;
    stress = expected?.stress;
    none = expected?.noSeizuresReported ?? false;
    dirty = false;
    validation = null;
  }

  @override
  void didUpdateWidget(covariant DailyCheckInForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date ||
        (!dirty && oldWidget.entry != widget.entry)) {
      _reset();
    }
  }

  @override
  void dispose() {
    sleep.dispose();
    effects.dispose();
    notes.dispose();
    super.dispose();
  }

  void _change(VoidCallback action) {
    HapticFeedback.selectionClick();
    setState(() {
      action();
      dirty = true;
      validation = null;
    });
  }

  Future<void> _save() async {
    HapticFeedback.selectionClick();
    final raw = sleep.text.trim().replaceAll(',', '.');
    final hours = raw.isEmpty ? null : double.tryParse(raw);
    if (raw.isNotEmpty &&
        (hours == null || !hours.isFinite || hours < 0 || hours > 24)) {
      setState(() => validation = 'Enter sleep between 0 and 24 hours.');
      return;
    }
    final draft = DailyLogDto(
      date: widget.date,
      sleepMinutes: hours == null ? null : (hours * 60).round(),
      sleepQuality: quality,
      mood: mood,
      stress: stress,
      sideEffects: effects.text.trim(),
      notes: notes.text.trim(),
      noSeizuresReported: !widget.hasSeizures && none,
    );
    final error = draft.validate(widget.controller.today);
    if (error != null) {
      setState(() => validation = error);
      return;
    }
    final saved = await widget.controller.save(draft, expected);
    if (!mounted) {
      return;
    }
    if (saved) {
      setState(() {
        expected = widget.controller.entry.value;
        dirty = false;
        validation = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Daily entry saved')));
    }
  }

  Future<void> _remove() async {
    HapticFeedback.selectionClick();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove daily check-in?'),
        content: const Text(
          'This removes the sleep, mood, stress, side effects and notes for this day. Seizure and cycle entries are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && expected != null) {
      final removed = await widget.controller.remove(expected!);
      if (removed && mounted) {
        setState(_reset);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final busy = widget.controller.saving.value;
    return Container(
      padding: const EdgeInsets.all(Dimensions.twenty),
      decoration: BoxDecoration(
        color: context.cardSurface,
        border: context.designBorder,
        borderRadius: BorderRadius.circular(context.design.cardRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Daily check-in',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Dimensions.eight),
            Text(
              dirty
                  ? 'Unsaved changes'
                  : expected == null
                  ? 'Not recorded · all fields optional'
                  : 'Saved · all fields optional',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
            ),
            const SizedBox(height: Dimensions.sixteen),
            if (widget.hasSeizures)
              const Text('Seizure entries are recorded for this day.')
            else
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('No seizures to report'),
                subtitle: const Text(
                  'Only select this if you are reporting no seizures for this day.',
                ),
                value: none,
                onChanged: busy ? null : (v) => _change(() => none = v == true),
              ),
            const SizedBox(height: Dimensions.sixteen),
            TextField(
              controller: sleep,
              enabled: !busy,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Sleep hours',
                hintText: 'Not recorded',
                helperText: 'Total sleep for the previous night (0–24)',
              ),
              onChanged: (_) => setState(() => dirty = true),
            ),
            const SizedBox(height: Dimensions.sixteen),
            _choices(
              'Sleep quality',
              DailyLogDto.qualities,
              quality,
              busy ? null : (v) => _change(() => quality = v),
            ),
            _choices(
              'Mood',
              DailyLogDto.moods,
              mood,
              busy ? null : (v) => _change(() => mood = v),
            ),
            _choices(
              'Stress',
              DailyLogDto.stresses,
              stress,
              busy ? null : (v) => _change(() => stress = v),
            ),
            TextField(
              controller: effects,
              enabled: !busy,
              maxLength: 200,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Side effects',
                hintText: 'Not recorded',
              ),
              onChanged: (_) => setState(() => dirty = true),
            ),
            const SizedBox(height: Dimensions.sixteen),
            TextField(
              controller: notes,
              enabled: !busy,
              maxLength: 500,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Daily notes',
                hintText: 'Not recorded',
              ),
              onChanged: (_) => setState(() => dirty = true),
            ),
            if (validation != null ||
                widget.controller.error.value != null) ...[
              const SizedBox(height: Dimensions.twelve),
              Text(validation ?? widget.controller.error.value!),
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        final confirmed =
                            !dirty ||
                            await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Discard daily changes?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Discard'),
                                      ),
                                    ],
                                  ),
                                ) ==
                                true;
                        if (confirmed) {
                          await widget.controller.load();
                          if (mounted) {
                            setState(_reset);
                          }
                        }
                      },
                child: const Text('Refresh daily entry'),
              ),
            ],
            const SizedBox(height: Dimensions.sixteen),
            FilledButton(
              onPressed: busy || !dirty ? null : _save,
              child: Text(busy ? 'Saving…' : 'Save daily entry'),
            ),
            if (expected != null)
              TextButton(
                onPressed: busy ? null : _remove,
                child: const Text('Remove daily check-in'),
              ),
          ],
        ),
      ),
    );
  });
  Widget _choices(
    String label,
    Map<String, String> options,
    String? selected,
    ValueChanged<String?>? onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: Dimensions.sixteen),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: Dimensions.eight),
        SingleChildScrollView(
          key: ValueKey('face-options-$label'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in <String?, String>{
                null: 'Not recorded',
                ...options,
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(right: Dimensions.eight),
                  child: ChoiceChip(
                    showCheckmark: false,
                    side: BorderSide.none,
                    backgroundColor: Colors.transparent,
                    selectedColor: context.ink.withValues(alpha: 0.08),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.eight,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          WellbeingFaceIcon(category: label, value: option.key),
                          const SizedBox(height: Dimensions.eight),
                          Text(option.value),
                        ],
                      ),
                    ),
                    selected: selected == option.key,
                    onSelected: onChanged == null
                        ? null
                        : (_) => onChanged(option.key),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
