import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/services/invite_service.dart';
import 'package:seizure_app/features/contacts/view_models/contacts_view_model.dart';

class AddContactBottomSheet extends StatefulWidget {
  const AddContactBottomSheet({super.key, this.existingContact});

  final ContactDto? existingContact;

  static Future<void> show({ContactDto? existingContact}) => showModalBottomSheet(
        context: Get.context!,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => AddContactBottomSheet(existingContact: existingContact),
      );

  @override
  State<AddContactBottomSheet> createState() => _AddContactBottomSheetState();
}

class _AddContactBottomSheetState extends State<AddContactBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();

  bool _notifyViaSms = true;
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
      _notifyViaSms = c.notifyViaSms;
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

    final vm = Get.find<ContactsViewModel>();
    final bool success;

    if (_isEditing) {
      success = await vm.updateContact(
        existing: widget.existingContact!,
        name: _nameController.text,
        phone: _phoneController.text,
        relation: _relationController.text.trim().isEmpty
            ? null
            : _relationController.text.trim(),
        notifyViaSms: _notifyViaSms,
        notifyViaPush: _notifyViaPush,
      );
    } else {
      success = await vm.addContact(
        name: _nameController.text,
        phone: _phoneController.text,
        relation: _relationController.text.trim().isEmpty
            ? null
            : _relationController.text.trim(),
        notifyViaSms: _notifyViaSms,
        notifyViaPush: _notifyViaPush,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Get.back();
      if (!_isEditing && _sendInvite) {
        InviteService.showInvitePicker(
          phone: _phoneController.text.trim(),
          contactName: _nameController.text.trim(),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Dimensions.twentyFour,
          Dimensions.twentyFour,
          Dimensions.twentyFour,
          Dimensions.twentyFour,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle ──────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _isEditing ? 'Edit Contact' : 'Add Contact',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: Dimensions.twentyFour),

              // ── Name ────────────────────────────────────────────────────
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

              // ── Phone ───────────────────────────────────────────────────
              _OutlinedFormField(
                controller: _phoneController,
                label: 'Phone Number',
                hintText: 'e.g. +27 82 123 4567',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Phone number is required'
                    : null,
              ),
              SizedBox(height: Dimensions.sixteen),

              // ── Relation ────────────────────────────────────────────────
              _OutlinedFormField(
                controller: _relationController,
                label: 'Relationship (optional)',
                hintText: 'e.g. Sister, Neurologist, Partner',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: Dimensions.twentyFour),

              // ── Notifications ───────────────────────────────────────────
              Text(
                'Alert Notifications',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
              ),
              SizedBox(height: Dimensions.twelve),
              _ToggleRow(
                label: 'Notify via SMS',
                value: _notifyViaSms,
                onChanged: (v) => setState(() => _notifyViaSms = v),
              ),
              const Divider(height: 1, color: Colors.black12),
              _ToggleRow(
                label: 'Notify via Push Notification',
                value: _notifyViaPush,
                onChanged: (v) => setState(() => _notifyViaPush = v),
              ),
              SizedBox(height: Dimensions.twentyFour),

              // ── Invite (new contacts only) ───────────────────────────────
              if (!_isEditing) ...[
                Text(
                  'App Invite',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                ),
                SizedBox(height: Dimensions.twelve),
                _ToggleRow(
                  label: 'Send invite to download SeizureAlert',
                  value: _sendInvite,
                  onChanged: (v) => setState(() => _sendInvite = v),
                ),
                SizedBox(height: Dimensions.eight),
                Text(
                  'Opens your SMS app with a pre-filled invite after saving.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.black38),
                ),
                SizedBox(height: Dimensions.twentyFour),
              ],

              // ── Save ────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black38,
                    padding:
                        EdgeInsets.symmetric(vertical: Dimensions.sixteen),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Save Changes' : 'Add to Circle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helper sub-widgets ───────────────────────────────────────────────────────

class _OutlinedFormField extends StatelessWidget {
  const _OutlinedFormField({
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
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
          Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium)),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.black,
            activeTrackColor: Colors.black54,
          ),
        ],
      );
}
