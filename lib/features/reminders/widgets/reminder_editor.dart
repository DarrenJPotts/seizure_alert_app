import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/medication_reminder_dto.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:seizure_app/features/reminders/view_models/reminders_view_model.dart';

class ReminderEditor extends StatefulWidget {
  const ReminderEditor({super.key, required this.controller, this.existing});
  final RemindersViewModel controller;
  final MedicationReminderDto? existing;
  @override
  State<ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends State<ReminderEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _dose;
  late ReminderKind _kind;
  late ReminderRepeat _repeat;
  late TimeOfDay _time;
  late DateTime _date;
  late Set<int> _days;
  late int _monthDay;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name);
    _dose = TextEditingController(text: existing?.dose);
    _kind = existing?.kind ?? ReminderKind.medication;
    _repeat = existing?.repeat ?? ReminderRepeat.daily;
    _time = TimeOfDay(hour: existing?.hour ?? 8, minute: existing?.minute ?? 0);
    _date = existing?.startDate ?? DateTime.now();
    _days = existing?.weekdays.toSet() ?? {};
    _monthDay = existing?.monthDay ?? _date.day;
  }

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppBottomSheetContent(
    child: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Dimensions.sixteen,
        children: [
          Text(
            widget.existing == null ? 'Add reminder' : 'Edit reminder',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          DropdownButtonFormField<ReminderKind>(
            initialValue: _kind,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Type'),
            items: [
              for (final kind in ReminderKind.values)
                DropdownMenuItem(
                  value: kind,
                  child: Text(
                    _kindLabel(kind),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _kind = value!),
          ),
          TextFormField(
            controller: _name,
            enabled: !_saving,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Take vitamins',
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter a name.' : null,
          ),
          if (_kind == ReminderKind.medication ||
              _kind == ReminderKind.supplement)
            TextFormField(
              controller: _dose,
              enabled: !_saving,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Dose (optional)'),
            ),
          DropdownButtonFormField<ReminderRepeat>(
            initialValue: _repeat,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Repeat'),
            items: [
              for (final repeat in ReminderRepeat.values)
                DropdownMenuItem(
                  value: repeat,
                  child: Text(
                    _repeatLabel(repeat),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() {
                    _repeat = value!;
                    if (_repeat == ReminderRepeat.weekly) {
                      _days = {_days.firstOrNull ?? _date.weekday};
                    }
                  }),
          ),
          if (_repeat == ReminderRepeat.weekly ||
              _repeat == ReminderRepeat.weekdays) ...[
            Text(
              _repeat == ReminderRepeat.weekly
                  ? 'Day of the week'
                  : 'Select days',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Wrap(
              spacing: Dimensions.eight,
              runSpacing: Dimensions.eight,
              children: [
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(
                      const [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ][day - 1],
                    ),
                    selected: _days.contains(day),
                    onSelected: _saving
                        ? null
                        : (selected) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (_repeat == ReminderRepeat.weekly) {
                                _days = {day};
                              } else if (selected) {
                                _days.add(day);
                              } else {
                                _days.remove(day);
                              }
                            });
                          },
                  ),
              ],
            ),
          ],
          if (_repeat == ReminderRepeat.monthly) ...[
            DropdownButtonFormField<int>(
              initialValue: _monthDay,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Day of month'),
              items: [
                for (var day = 1; day <= 31; day++)
                  DropdownMenuItem(value: day, child: Text('Day $day')),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _monthDay = value!),
            ),
            const Text('Days 29–31 skip months without that date.'),
          ],
          OutlinedButton.icon(
            onPressed: _saving ? null : _chooseDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
              '${_repeat == ReminderRepeat.once ? 'Date' : 'Start date'}: ${_date.day}/${_date.month}/${_date.year}',
            ),
          ),
          OutlinedButton.icon(
            onPressed: _saving ? null : _chooseTime,
            icon: const Icon(Icons.schedule_outlined),
            label: Text('Time: ${_time.format(context)}'),
          ),
          if (_error != null)
            Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save reminder'),
          ),
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );

  Future<void> _chooseDate() async {
    HapticFeedback.selectionClick();
    final today = DateTime.now();
    final earliest = DateTime(today.year, today.month, today.day);
    final date = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(earliest) ? earliest : _date,
      firstDate: earliest,
      lastDate: DateTime(today.year + 10, 12, 31),
    );
    if (mounted && date != null) setState(() => _date = date);
  }

  Future<void> _chooseTime() async {
    HapticFeedback.selectionClick();
    final time = await showTimePicker(context: context, initialTime: _time);
    if (mounted && time != null) setState(() => _time = time);
  }

  Future<void> _save() async {
    HapticFeedback.selectionClick();
    if (!_form.currentState!.validate()) return;
    final existing = widget.existing;
    final value = MedicationReminderDto(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      dose: _dose.text.trim().isEmpty ? null : _dose.text.trim(),
      hour: _time.hour,
      minute: _time.minute,
      kind: _kind,
      repeat: _repeat,
      startDate: DateTime(_date.year, _date.month, _date.day),
      weekdays: _days.toList()..sort(),
      monthDay: _monthDay,
      enabled: existing?.enabled ?? true,
    );
    if (value.validationError != null) {
      setState(() => _error = value.validationError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await widget.controller.saveReminder(
      value,
      expectedRevision: existing?.revision,
    );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = widget.controller.error.value ?? 'Could not save. Try again.';
      });
    }
  }
}

String _kindLabel(ReminderKind kind) => switch (kind) {
  ReminderKind.medication => 'Medication',
  ReminderKind.supplement => 'Vitamin / supplement',
  ReminderKind.appointment => 'Appointment',
  ReminderKind.custom => 'Custom',
};
String _repeatLabel(ReminderRepeat repeat) => switch (repeat) {
  ReminderRepeat.once => 'Once',
  ReminderRepeat.daily => 'Daily',
  ReminderRepeat.weekdays => 'Selected weekdays',
  ReminderRepeat.weekly => 'Weekly',
  ReminderRepeat.monthly => 'Monthly',
};
