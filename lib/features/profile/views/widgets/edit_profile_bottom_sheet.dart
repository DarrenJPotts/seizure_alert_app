import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';

typedef UpdateProfileCallback =
    Future<bool> Function({
      required String displayName,
      String? phone,
      String? bloodType,
      String? seizureType,
      List<String>? medications,
      String? emergencyNote,
    });

class EditProfileBottomSheet extends StatefulWidget {
  const EditProfileBottomSheet({
    super.key,
    required this.user,
    required this.onSave,
  });

  final UserDto? user;
  final UpdateProfileCallback onSave;

  static Future<void> show({
    required UserDto? user,
    required UpdateProfileCallback onSave,
  }) => AppBottomSheet.show(
    context: Get.context!,
    builder: (_) => EditProfileBottomSheet(user: user, onSave: onSave),
  );

  @override
  State<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<EditProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _seizureTypeController;
  late final TextEditingController _medicationsController;
  late final TextEditingController _emergencyNoteController;

  String? _selectedBloodType;
  bool _isSaving = false;

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _seizureTypeController = TextEditingController(
      text: user?.seizureType ?? '',
    );
    _medicationsController = TextEditingController(
      text: user?.medications?.join(', ') ?? '',
    );
    _emergencyNoteController = TextEditingController(
      text: user?.emergencyNote ?? '',
    );
    _selectedBloodType = user?.bloodType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _seizureTypeController.dispose();
    _medicationsController.dispose();
    _emergencyNoteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final meds = _medicationsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final success = await widget.onSave(
      displayName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      bloodType: _selectedBloodType,
      seizureType: _seizureTypeController.text.trim(),
      medications: meds.isEmpty ? null : meds,
      emergencyNote: _emergencyNoteController.text.trim(),
    );

    setState(() => _isSaving = false);
    if (success) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetContent(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Dimensions.twentyFour,
          children: [
            Text(
              'Edit Profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            _LabeledField(
              label: 'Name',
              child: TextFormField(
                controller: _nameController,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: _inputDeco(hint: 'Your full name'),
              ),
            ),

            _LabeledField(
              label: 'Phone Number',
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: _inputDeco(hint: 'Your phone number'),
              ),
            ),

            _LabeledField(
              label: 'Blood Type',
              child: DropdownButtonFormField<String>(
                initialValue: _selectedBloodType,
                hint: Text(
                  'Select',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black38),
                ),
                decoration: _inputDeco(),
                items: _bloodTypes
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedBloodType = v),
                dropdownColor: Colors.white,
                iconEnabledColor: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            _LabeledField(
              label: 'Seizure Type',
              child: TextFormField(
                controller: _seizureTypeController,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: _inputDeco(hint: 'e.g. Focal, Tonic-clonic'),
              ),
            ),

            _LabeledField(
              label: 'Medications',
              child: TextFormField(
                controller: _medicationsController,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: _inputDeco(
                  hint: 'e.g. Lamotrigine, Valproate',
                  helper: 'Separate multiple medications with a comma',
                ),
              ),
            ),

            _LabeledField(
              label: 'Emergency Note',
              child: TextFormField(
                controller: _emergencyNoteController,
                maxLines: 4,
                maxLength: 240,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: _inputDeco(
                  hint: 'Information for first responders...',
                ),
              ),
            ),

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
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isSaving ? null : () => Get.back(),
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco({String? hint, String? helper}) => InputDecoration(
    hintText: hint,
    helperText: helper,
    hintStyle: Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: Colors.black38),
    helperStyle: Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.black45),
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
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Dimensions.eight,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        child,
      ],
    );
  }
}
