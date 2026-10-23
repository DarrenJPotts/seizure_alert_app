import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:seizure_app/core/widgets/duration_stepper_field.dart';

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
    this.initialOccurredAt,
  });

  final SeizureLogDto? existingLog;
  final DateTime? initialOccurredAt;
  final AddSeizureLogCallback onAdd;
  final UpdateSeizureLogCallback onUpdate;

  static Future<void> show({
    required AddSeizureLogCallback onAdd,
    required UpdateSeizureLogCallback onUpdate,
    SeizureLogDto? existingLog,
    DateTime? initialOccurredAt,
  }) => AppBottomSheet.show(
    context: Get.context!,
    builder: (_) => AddSeizureLogBottomSheet(
      onAdd: onAdd,
      onUpdate: onUpdate,
      existingLog: existingLog,
      initialOccurredAt: initialOccurredAt,
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
      _occurredAt = widget.initialOccurredAt ?? DateTime.now();
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
            const SizedBox(height: Dimensions.twentyFour),

            const _SectionLabel(label: 'Date & Time'),
            const SizedBox(height: Dimensions.eight),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(context.design.cardRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.sixteen,
                  vertical: Dimensions.sixteen,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: context.ink.withValues(alpha: 0.12),
                  ),
                  borderRadius: BorderRadius.circular(
                    context.design.cardRadius,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: context.secondaryInk,
                    ),
                    const SizedBox(width: Dimensions.twelve),
                    Expanded(
                      child: Text(
                        _formatDateTime(_occurredAt),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: context.ink.withValues(alpha: 0.26),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Dimensions.sixteen),

            const _SectionLabel(label: 'Duration (optional)'),
            const SizedBox(height: Dimensions.eight),
            Row(
              spacing: Dimensions.eight,
              children: [
                Expanded(
                  child: DurationStepperField(
                    key: const ValueKey('entry-duration-minutes'),
                    value: int.tryParse(_minutesController.text) ?? 0,
                    label: 'Minutes',
                    maxValue: 99,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      setState(() => _minutesController.text = '$value');
                    },
                  ),
                ),
                Text(':', style: Theme.of(context).textTheme.headlineMedium),
                Expanded(
                  child: DurationStepperField(
                    key: const ValueKey('entry-duration-seconds'),
                    value: int.tryParse(_secondsController.text) ?? 0,
                    label: 'Seconds',
                    maxValue: 59,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      setState(() => _secondsController.text = '$value');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.sixteen),

            const _SectionLabel(label: 'Clinical details (optional)'),
            const SizedBox(height: Dimensions.eight),
            _OutlinedTextField(
              controller: _seizureTypeController,
              hintText: 'Seizure type',
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: Dimensions.twelve),
            LayoutBuilder(
              builder: (context, constraints) {
                final painter = TextPainter(
                  text: TextSpan(
                    text: 'Unconscious',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout();
                final fits =
                    constraints.maxWidth >=
                    (painter.width +
                                Dimensions.sixteen * 2 +
                                Dimensions.twentyFour +
                                Dimensions.eight) *
                            2 +
                        Dimensions.twelve;
                painter.dispose();
                final severity = _ClinicalChoice(
                  label: 'Severity',
                  value: _severity,
                  options: const ['Mild', 'Moderate', 'Severe'],
                  onChanged: (value) => setState(() => _severity = value),
                );
                final awareness = _ClinicalChoice(
                  label: 'Awareness',
                  value: _awareness,
                  options: const [
                    'Aware',
                    'Impaired',
                    'Unconscious',
                    'Unknown',
                  ],
                  onChanged: (value) => setState(() => _awareness = value),
                );
                return fits
                    ? Row(
                        children: [
                          Expanded(child: severity),
                          const SizedBox(width: Dimensions.twelve),
                          Expanded(child: awareness),
                        ],
                      )
                    : Column(
                        children: [
                          severity,
                          const SizedBox(height: Dimensions.twelve),
                          awareness,
                        ],
                      );
              },
            ),
            const SizedBox(height: Dimensions.twelve),
            _OutlinedTextField(
              controller: _auraController,
              hintText: 'Aura or warning signs',
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: Dimensions.twelve),
            _OutlinedTextField(
              controller: _injuriesController,
              hintText: 'Injuries or complications',
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: Dimensions.twelve),
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
            const SizedBox(height: Dimensions.eight),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeTrackColor: context.ink,
              title: const Text('Rescue medication used'),
              value: _rescueMedicationUsed,
              onChanged: (bool value) =>
                  setState(() => _rescueMedicationUsed = value),
            ),
            const SizedBox(height: Dimensions.sixteen),

            const _SectionLabel(label: 'Location (optional)'),
            const SizedBox(height: Dimensions.eight),
            _OutlinedTextField(
              controller: _locationController,
              hintText: 'e.g. Home, Work, Gym',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: Dimensions.sixteen),

            const _SectionLabel(label: 'Trigger (optional)'),
            const SizedBox(height: Dimensions.eight),
            _OutlinedTextField(
              controller: _triggerController,
              hintText: 'e.g. Stress, Lack of sleep',
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: Dimensions.sixteen),

            const _SectionLabel(label: 'Notes (optional)'),
            const SizedBox(height: Dimensions.eight),
            _OutlinedTextField(
              controller: _notesController,
              hintText: 'Any additional observations…',
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: Dimensions.twentyFour),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.ink,
                  foregroundColor: context.paper,
                  disabledBackgroundColor: context.ink.withValues(alpha: 0.38),
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.sixteen,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      context.design.cardRadius,
                    ),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: context.paper,
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
      color: context.secondaryInk,
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

class _ClinicalChoice extends StatelessWidget {
  const _ClinicalChoice({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    isDense: false,
    itemHeight: null,
    decoration: InputDecoration(labelText: label),
    items: options
        .map((option) => DropdownMenuItem(value: option, child: Text(option)))
        .toList(),
    onChanged: onChanged,
  );
}
