import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';

typedef AddSeizureLogCallback =
    Future<bool> Function({
      required DateTime occurredAt,
      int? durationSeconds,
      String? location,
      String? trigger,
      String? notes,
      String? seizureType,
      String? aura,
      String? severity,
      String? awareness,
      String? injuries,
      int? recoveryMinutes,
      bool rescueMedicationUsed,
      bool alertFired,
    });

typedef UpdateSeizureLogCallback =
    Future<bool> Function({
      required String id,
      required DateTime occurredAt,
      int? durationSeconds,
      String? location,
      String? trigger,
      String? notes,
      String? seizureType,
      String? aura,
      String? severity,
      String? awareness,
      String? injuries,
      int? recoveryMinutes,
      bool rescueMedicationUsed,
      bool alertFired,
    });

class AddSeizureLogBottomSheet extends StatefulWidget {
  const AddSeizureLogBottomSheet({
    super.key,
    required this.onAdd,
    required this.onUpdate,
    this.existingLog,
  });

  final SeizureLogDto? existingLog;
  final AddSeizureLogCallback onAdd;
  final UpdateSeizureLogCallback onUpdate;

  static Future<void> show({
    required AddSeizureLogCallback onAdd,
    required UpdateSeizureLogCallback onUpdate,
    SeizureLogDto? existingLog,
  }) => AppBottomSheet.show(
    context: Get.context!,
    builder: (_) => AddSeizureLogBottomSheet(
      onAdd: onAdd,
      onUpdate: onUpdate,
      existingLog: existingLog,
    ),
  );

  @override
  State<AddSeizureLogBottomSheet> createState() =>
      _AddSeizureLogBottomSheetState();
}

class _AddSeizureLogBottomSheetState extends State<AddSeizureLogBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _occurredAt;
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  final _locationController = TextEditingController();
  final _triggerController = TextEditingController();
  final _notesController = TextEditingController();
  final _seizureTypeController = TextEditingController();
  final _auraController = TextEditingController();
  final _injuriesController = TextEditingController();
  final _recoveryController = TextEditingController();
  String? _severity;
  String? _awareness;
  bool _rescueMedicationUsed = false;

  bool _isSaving = false;

  bool get _isEditing => widget.existingLog != null;

  @override
  void initState() {
    super.initState();
    final log = widget.existingLog;
    if (log != null) {
      _occurredAt = log.occurredAt;
      final dur = log.durationSeconds ?? 0;
      if (dur > 0) {
        _minutesController.text = (dur ~/ 60).toString();
        _secondsController.text = (dur % 60).toString();
      }
      _locationController.text = log.location ?? '';
      _triggerController.text = log.trigger ?? '';
      _notesController.text = log.notes ?? '';
      _seizureTypeController.text = log.seizureType ?? '';
      _auraController.text = log.aura ?? '';
      _injuriesController.text = log.injuries ?? '';
      _recoveryController.text = log.recoveryMinutes?.toString() ?? '';
      _severity = log.severity;
      _awareness = log.awareness;
      _rescueMedicationUsed = log.rescueMedicationUsed;
    } else {
      _occurredAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    _locationController.dispose();
    _triggerController.dispose();
    _notesController.dispose();
    _seizureTypeController.dispose();
    _auraController.dispose();
    _injuriesController.dispose();
    _recoveryController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (time == null) return;

    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final seconds = int.tryParse(_secondsController.text.trim()) ?? 0;
    final totalSeconds = (minutes * 60 + seconds).clamp(0, 99999);
    final int? recoveryMinutes = int.tryParse(_recoveryController.text.trim());

    final bool success;

    if (_isEditing) {
      success = await widget.onUpdate(
        id: widget.existingLog!.id,
        occurredAt: _occurredAt,
        durationSeconds: totalSeconds > 0 ? totalSeconds : null,
        location: _locationController.text,
        trigger: _triggerController.text,
        notes: _notesController.text,
        seizureType: _seizureTypeController.text,
        aura: _auraController.text,
        severity: _severity,
        awareness: _awareness,
        injuries: _injuriesController.text,
        recoveryMinutes: recoveryMinutes,
        rescueMedicationUsed: _rescueMedicationUsed,
        alertFired: widget.existingLog!.alertFired,
      );
    } else {
      success = await widget.onAdd(
        occurredAt: _occurredAt,
        durationSeconds: totalSeconds > 0 ? totalSeconds : null,
        location: _locationController.text,
        trigger: _triggerController.text,
        notes: _notesController.text,
        seizureType: _seizureTypeController.text,
        aura: _auraController.text,
        severity: _severity,
        awareness: _awareness,
        injuries: _injuriesController.text,
        recoveryMinutes: recoveryMinutes,
        rescueMedicationUsed: _rescueMedicationUsed,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Get.back();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save. Please try again.')),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  $h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetContent(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _isEditing ? 'Edit Entry' : 'Add Seizure Entry',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
            SizedBox(height: Dimensions.twentyFour),

            _SectionLabel(label: 'Date & Time'),
            SizedBox(height: Dimensions.eight),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.sixteen,
                  vertical: Dimensions.sixteen,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Colors.black54,
                    ),
                    SizedBox(width: Dimensions.twelve),
                    Expanded(
                      child: Text(
                        _formatDateTime(_occurredAt),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: Dimensions.sixteen),

            _SectionLabel(label: 'Duration (optional)'),
            SizedBox(height: Dimensions.eight),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: _minutesController,
                    label: 'Minutes',
                    max: 99,
                  ),
                ),
                SizedBox(width: Dimensions.twelve),
                Expanded(
                  child: _NumberField(
                    controller: _secondsController,
                    label: 'Seconds',
                    max: 59,
                  ),
                ),
              ],
            ),
            SizedBox(height: Dimensions.sixteen),

            _SectionLabel(label: 'Clinical details (optional)'),
            SizedBox(height: Dimensions.eight),
            _OutlinedTextField(
              controller: _seizureTypeController,
              hintText: 'Seizure type',
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: Dimensions.twelve),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _severity,
                    decoration: const InputDecoration(labelText: 'Severity'),
                    items: const <String>['Mild', 'Moderate', 'Severe']
                        .map(
                          (String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) =>
                        setState(() => _severity = value),
                  ),
                ),
                SizedBox(width: Dimensions.twelve),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _awareness,
                    decoration: const InputDecoration(labelText: 'Awareness'),
                    items:
                        const <String>[
                              'Aware',
                              'Impaired',
                              'Unconscious',
                              'Unknown',
                            ]
                            .map(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (String? value) =>
                        setState(() => _awareness = value),
                  ),
                ),
              ],
            ),
            SizedBox(height: Dimensions.twelve),
            _OutlinedTextField(
              controller: _auraController,
              hintText: 'Aura or warning signs',
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: Dimensions.twelve),
            _OutlinedTextField(
              controller: _injuriesController,
              hintText: 'Injuries or complications',
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: Dimensions.twelve),
            TextFormField(
              controller: _recoveryController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                const _MaxValueFormatter(1440),
              ],
              decoration: const InputDecoration(
                labelText: 'Recovery time in minutes',
              ),
            ),
            SizedBox(height: Dimensions.eight),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeTrackColor: Colors.black,
              title: const Text('Rescue medication used'),
              value: _rescueMedicationUsed,
              onChanged: (bool value) =>
                  setState(() => _rescueMedicationUsed = value),
            ),
            SizedBox(height: Dimensions.sixteen),

            _SectionLabel(label: 'Location (optional)'),
            SizedBox(height: Dimensions.eight),
            _OutlinedTextField(
              controller: _locationController,
              hintText: 'e.g. Home, Work, Gym',
              textCapitalization: TextCapitalization.words,
            ),
            SizedBox(height: Dimensions.sixteen),

            _SectionLabel(label: 'Trigger (optional)'),
            SizedBox(height: Dimensions.eight),
            _OutlinedTextField(
              controller: _triggerController,
              hintText: 'e.g. Stress, Lack of sleep',
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: Dimensions.sixteen),

            _SectionLabel(label: 'Notes (optional)'),
            SizedBox(height: Dimensions.eight),
            _OutlinedTextField(
              controller: _notesController,
              hintText: 'Any additional observations…',
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: Dimensions.twentyFour),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.black38,
                  padding: EdgeInsets.symmetric(vertical: Dimensions.sixteen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Save Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: Colors.black54,
    ),
  );
}

class _OutlinedTextField extends StatelessWidget {
  const _OutlinedTextField({
    required this.controller,
    this.hintText,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    textCapitalization: textCapitalization,
    decoration: InputDecoration(hintText: hintText),
  );
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.max,
  });

  final TextEditingController controller;
  final String label;
  final int max;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      _MaxValueFormatter(max),
    ],
    decoration: InputDecoration(labelText: label),
  );
}

class _MaxValueFormatter extends TextInputFormatter {
  const _MaxValueFormatter(this.max);
  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final value = int.tryParse(newValue.text) ?? 0;
    return value > max ? oldValue : newValue;
  }
}
