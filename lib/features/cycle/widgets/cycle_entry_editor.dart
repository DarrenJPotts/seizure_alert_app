import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/cycle_tracking_dto.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import '../view_models/cycle_view_model.dart';

class CycleEntryEditor extends StatefulWidget {
  const CycleEntryEditor({
    super.key,
    required this.controller,
    this.existing,
    this.initialDate,
  });
  final CycleViewModel controller;
  final CycleEntryDto? existing;
  final DateTime? initialDate;
  @override
  State<CycleEntryEditor> createState() => _CycleEntryEditorState();
}

class _CycleEntryEditorState extends State<CycleEntryEditor> {
  late final String _id;
  late DateTime _start;
  DateTime? _end;
  late bool _ongoing;
  late CycleFlow _flow;
  late TextEditingController _symptoms;
  late TextEditingController _notes;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _id = widget.existing?.id ?? widget.controller.newEntryId();
    _start =
        widget.existing?.start ?? widget.initialDate ?? widget.controller.today;
    _end = widget.existing?.end;
    _ongoing = _end == null;
    _flow = widget.existing?.flow ?? CycleFlow.notRecorded;
    _symptoms = TextEditingController(text: widget.existing?.symptoms);
    _notes = TextEditingController(text: widget.existing?.notes);
  }

  @override
  void dispose() {
    _symptoms.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    HapticFeedback.selectionClick();
    final today = widget.controller.today;
    final initial = start ? _start : _end ?? _start;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(today) ? today : initial,
      firstDate: DateTime(1900),
      lastDate: today,
    );
    if (selected != null && mounted) {
      setState(() {
        if (start) {
          _start = selected;
        } else {
          _end = selected;
        }
      });
    }
  }

  Future<void> _save() async {
    HapticFeedback.selectionClick();
    setState(() {
      _saving = true;
      _error = null;
    });
    final entry = CycleEntryDto(
      id: _id,
      start: _start,
      end: _ongoing ? null : _end ?? _start,
      flow: _flow,
      symptoms: _symptoms.text.trim(),
      notes: _notes.text.trim(),
    );
    final saved = await widget.controller.save(entry);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = widget.controller.error.value ?? 'Could not save. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AppBottomSheetContent(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.existing == null ? 'Add period entry' : 'Edit period entry',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Dimensions.sixteen),
        OutlinedButton(
          onPressed: _saving ? null : () => _pick(true),
          child: Text(
            'Start date: ${MaterialLocalizations.of(context).formatMediumDate(_start)}',
          ),
        ),
        const SizedBox(height: Dimensions.twelve),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ongoing'),
          subtitle: const Text(
            'Mark recorded days through today until you add an end date.',
          ),
          value: _ongoing,
          onChanged: _saving
              ? null
              : (value) {
                  HapticFeedback.selectionClick();
                  setState(() => _ongoing = value);
                },
        ),
        if (!_ongoing) ...[
          const SizedBox(height: Dimensions.twelve),
          OutlinedButton(
            onPressed: _saving ? null : () => _pick(false),
            child: Text(
              'End date: ${MaterialLocalizations.of(context).formatMediumDate(_end ?? _start)}',
            ),
          ),
        ],
        const SizedBox(height: Dimensions.sixteen),
        DropdownButtonFormField<CycleFlow>(
          initialValue: _flow,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Flow (optional)'),
          items: [
            for (final flow in CycleFlow.values)
              DropdownMenuItem(value: flow, child: Text(flow.label)),
          ],
          onChanged: _saving ? null : (value) => setState(() => _flow = value!),
        ),
        const SizedBox(height: Dimensions.sixteen),
        TextField(
          controller: _symptoms,
          enabled: !_saving,
          maxLength: 200,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Symptoms (optional)'),
        ),
        const SizedBox(height: Dimensions.twelve),
        TextField(
          controller: _notes,
          enabled: !_saving,
          maxLength: 500,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
        ),
        if (_error != null) ...[
          const SizedBox(height: Dimensions.twelve),
          Text(_error!),
        ],
        const SizedBox(height: Dimensions.sixteen),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save entry'),
        ),
      ],
    ),
  );
}
