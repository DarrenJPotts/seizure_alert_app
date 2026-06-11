import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/profile/view_models/profile_view_model.dart';

class EditProfileBottomSheet extends StatefulWidget {
  const EditProfileBottomSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const EditProfileBottomSheet(),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  @override
  State<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<EditProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _seizureTypeController;
  late final TextEditingController _medicationsController;
  late final TextEditingController _emergencyNoteController;

  String? _selectedBloodType;
  bool _isSaving = false;

  static const _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-',
  ];

  @override
  void initState() {
    super.initState();
    final user = Get.find<ProfileViewModel>().user.value;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _seizureTypeController = TextEditingController(text: user?.seizureType ?? '');
    _medicationsController = TextEditingController(
      text: user?.medications?.join(', ') ?? '',
    );
    _emergencyNoteController =
        TextEditingController(text: user?.emergencyNote ?? '');
    _selectedBloodType = user?.bloodType;
  }

  @override
  void dispose() {
    _nameController.dispose();
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

    final success = await Get.find<ProfileViewModel>().updateProfile(
      displayName: _nameController.text.trim(),
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
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Dimensions.twentyFour,
          Dimensions.twenty,
          Dimensions.twentyFour,
          Dimensions.thirtyTwo,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Dimensions.twentyFour,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text('Edit Profile',
                  style: Theme.of(context).textTheme.titleMedium),

              _LabeledField(
                label: 'Name',
                child: TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 14),
                  decoration: _inputDeco(hint: 'Your full name'),
                ),
              ),

              _LabeledField(
                label: 'Blood Type',
                child: DropdownButtonFormField<String>(
                  value: _selectedBloodType,
                  hint: const Text('Select',
                      style:
                          TextStyle(color: Colors.black38, fontSize: 14)),
                  decoration: _inputDeco(),
                  items: _bloodTypes
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t,
                                style: const TextStyle(fontSize: 14)),
                          ))
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
                  style: const TextStyle(fontSize: 14),
                  decoration:
                      _inputDeco(hint: 'e.g. Focal, Tonic-clonic'),
                ),
              ),

              _LabeledField(
                label: 'Medications',
                child: TextFormField(
                  controller: _medicationsController,
                  style: const TextStyle(fontSize: 14),
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
                  style: const TextStyle(fontSize: 14),
                  decoration: _inputDeco(
                      hint: 'Information for first responders...'),
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
                    padding: EdgeInsets.symmetric(
                        vertical: Dimensions.sixteen),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static InputDecoration _inputDeco({String? hint, String? helper}) =>
      InputDecoration(
        hintText: hint,
        helperText: helper,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        helperStyle:
            const TextStyle(color: Colors.black45, fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
