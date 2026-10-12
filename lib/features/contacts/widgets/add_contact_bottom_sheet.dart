import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/formatters/south_african_phone_input_formatter.dart';
import 'package:seizure_app/core/helpers/phone_number.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/services/circle_invite_service.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:seizure_app/features/contacts/widgets/invite_picker_sheet.dart';

typedef AddContactCallback =
    Future<ContactDto?> Function({
      required String name,
      required String phone,
      String? relation,
      bool notifyViaPush,
    });

typedef UpdateContactCallback =
    Future<bool> Function({
      required ContactDto existing,
      required String name,
      required String phone,
      String? relation,
      bool notifyViaPush,
    });

typedef SendInviteCallback =
    Future<ResultDto<String>> Function({required String contactId});

class AddContactBottomSheet extends StatefulWidget {
  const AddContactBottomSheet({
    super.key,
    required this.onAdd,
    required this.onUpdate,
    required this.onSendInvite,
    this.existingContact,
  });

  final ContactDto? existingContact;
  final AddContactCallback onAdd;
  final UpdateContactCallback onUpdate;
  final SendInviteCallback onSendInvite;

  static Future<void> show({
    required AddContactCallback onAdd,
    required UpdateContactCallback onUpdate,
    required SendInviteCallback onSendInvite,
    ContactDto? existingContact,
  }) => AppBottomSheet.show(
    context: Get.context!,
    builder: (_) => AddContactBottomSheet(
      onAdd: onAdd,
      onUpdate: onUpdate,
      onSendInvite: onSendInvite,
      existingContact: existingContact,
    ),
  );

  @override
  State<AddContactBottomSheet> createState() => _AddContactBottomSheetState();
}

class _AddContactBottomSheetState extends State<AddContactBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();

  bool _notifyViaPush = true;
  bool _sendInvite = true;
  bool _isSaving = false;

  bool get _isEditing => widget.existingContact != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingContact;
    if (c != null) {
      _nameController.text = c.name;
      _phoneController.text = c.phone;
      _relationController.text = c.relation ?? '';
      _notifyViaPush = c.notifyViaPush;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final bool success;
    ContactDto? createdContact;

    if (_isEditing) {
      success = await widget.onUpdate(
        existing: widget.existingContact!,
        name: _nameController.text,
        phone: _phoneController.text,
        relation: _relationController.text.trim().isEmpty
            ? null
            : _relationController.text.trim(),
        notifyViaPush: _notifyViaPush,
      );
    } else {
      createdContact = await widget.onAdd(
        name: _nameController.text,
        phone: _phoneController.text,
        relation: _relationController.text.trim().isEmpty
            ? null
            : _relationController.text.trim(),
        notifyViaPush: _notifyViaPush,
      );
      success = createdContact != null;
    }

    if (!mounted) return;

    if (success) {
      final contactToInvite = createdContact;
      if (!_isEditing && _sendInvite && contactToInvite != null) {
        final sendInvite = widget.onSendInvite;
        Get.back();
        AppBottomSheet.show(
          context: Get.context!,
          builder: (_) => InvitePickerSheet(
            phone: contactToInvite.phone,
            contactName: contactToInvite.name,
            loadCode: () => sendInvite(contactId: contactToInvite.id),
            onRegenerate: () =>
                CircleInviteService.instance().createCircleInvite(
                  contactId: contactToInvite.id,
                  regenerate: true,
                ),
          ),
        );
        return;
      }
      Get.back();
    } else {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save. Please try again.')),
      );
    }
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
            Text(
              _isEditing ? 'Edit Contact' : 'Add Contact',
              style: context.theme.textTheme.titleMedium,
            ),
            SizedBox(height: Dimensions.twentyFour),

            _OutlinedFormField(
              controller: _nameController,
              label: 'Full Name',
              hintText: 'e.g. Sarah Johnson',
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            SizedBox(height: Dimensions.sixteen),

            _OutlinedFormField(
              controller: _phoneController,
              label: 'Phone Number',
              hintText: 'e.g. +27 82 123 4567',
              keyboardType: TextInputType.phone,
              inputFormatters: const <TextInputFormatter>[
                SouthAfricanPhoneInputFormatter(),
              ],
              textInputAction: TextInputAction.next,
              maxLength: SouthAfricanPhoneInputFormatter.maxLength,
              validator: (v) => PhoneNumber.validationError(v, required: true),
            ),
            SizedBox(height: Dimensions.sixteen),

            _OutlinedFormField(
              controller: _relationController,
              label: 'Relationship (optional)',
              hintText: 'e.g. Sister, Neurologist, Partner',
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
            ),
            SizedBox(height: Dimensions.twentyFour),

            Text(
              'Emergency Alerts',
              style: context.theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: Dimensions.twelve),
            _ToggleRow(
              label: 'Notify via push notifications',
              value: _notifyViaPush,
              onChanged: (v) => setState(() => _notifyViaPush = v),
            ),
            SizedBox(height: Dimensions.twentyFour),

            if (!_isEditing) ...[
              Text(
                'App Invite',
                style: context.theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: Dimensions.twelve),
              _ToggleRow(
                label: 'Invite to join your circle',
                value: _sendInvite,
                onChanged: (v) => setState(() => _sendInvite = v),
              ),
              SizedBox(height: Dimensions.eight),
              Text(
                'Creates a one-time code to share by SMS or WhatsApp after saving. '
                'They sign in and enter the code to accept.',
                style: context.theme.textTheme.bodySmall?.copyWith(
                  color: Colors.black38,
                ),
              ),
              SizedBox(height: Dimensions.twentyFour),
            ],

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
                    : Text(_isEditing ? 'Save Changes' : 'Add to Circle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlinedFormField extends StatelessWidget {
  const _OutlinedFormField({
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    maxLength: maxLength,
    maxLengthEnforcement: MaxLengthEnforcement.enforced,
    textCapitalization: textCapitalization,
    textInputAction: textInputAction,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      hintText: hintText,
      counterText: maxLength == null ? null : '',
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: context.theme.textTheme.bodyMedium)),
      Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.black,
        activeTrackColor: Colors.black54,
      ),
    ],
  );
}
