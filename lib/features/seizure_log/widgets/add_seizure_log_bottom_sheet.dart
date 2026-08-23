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
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

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

    final bool success;

    if (_isEditing) {
      success = await widget.onUpdate(
        id: widget.existingLog!.id,
        occurredAt: _occurredAt,
        durationSeconds: totalSeconds > 0 ? totalSeconds : null,
        location: _locationController.text,
        trigger: _triggerController.text,
        notes: _notesController.text,
        alertFired: widget.existingLog!.alertFired,
      );
    } else {
      success = await widget.onAdd(
        occurredAt: _occurredAt,
        durationSeconds: totalSeconds > 0 ? totalSeconds : null,
        location: _locationController.text,
        trigger: _triggerController.text,
        notes: _notesController.text,
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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetContent(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Entry' : 'Add Seizure Entry',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: Dimensions.twentyFour),

            // ── Date / Time ─────────────────────────────────────────────
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

            // ── Duration ────────────────────────────────────────────────
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

            // ── Location ────────────────────────────────────────────────
            _SectionLabel(label: 'Location (optional)'),
            SizedBox(height: Dimensions.eight),
            _OutlinedTextField(
              controller: _locationController,
              hintText: 'e.g. Home, Work, Gym',
              textCapitalization: TextCapitalization.words,
            ),
            SizedBox(height: Dimensions.sixteen),

            // ── Trigger ─────────────────────────────────────────────────
            _SectionLabel(label: 'Trigger (optional)'),
            SizedBox(height: Dimensions.eight),
            _OutlinedTextField(
              controller: _triggerController,
              hintText: 'e.g. Stress, Lack of sleep',
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: Dimensions.sixteen),

            // ── Notes ───────────────────────────────────────────────────
            _SectionLabel(label: 'Notes (optional)'),
            SizedBox(height: Dimensions.eight),
            _OutlinedTextField(
              controller: _notesController,
              hintText: 'Any additional observations…',
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: Dimensions.twentyFour),

            // ── Save ────────────────────────────────────────────────────
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

// ─── Helper sub-widgets ───────────────────────────────────────────────────────

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
    decoration: _inputDecoration(hintText: hintText),
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
    decoration: _inputDecoration(labelText: label),
  );
}

InputDecoration _inputDecoration({String? labelText, String? hintText}) =>
    InputDecoration(
      labelText: labelText,
      hintText: hintText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
    );

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
