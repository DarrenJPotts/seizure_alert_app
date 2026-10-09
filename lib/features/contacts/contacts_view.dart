import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/features/contacts/view_models/contacts_view_model.dart';
import 'package:seizure_app/features/contacts/widgets/add_contact_bottom_sheet.dart';
import 'package:seizure_app/features/contacts/widgets/contact_card.dart';
import 'package:seizure_app/features/contacts/widgets/invite_picker_sheet.dart';

class ContactsView extends GetView<ContactsViewModel> {
  const ContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(
            Dimensions.twentyFour,
          ).copyWith(bottom: Dimensions.twelve),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Circle', style: context.theme.textTheme.titleMedium),
              Wrap(
                spacing: Dimensions.four,
                children: [
                  IconButton(
                    tooltip: 'Enter invite code',
                    onPressed: () => Get.toNamed(AppRoutes.circleInvite),
                    icon: const Icon(Icons.key_outlined),
                  ),
                  TextButton.icon(
                    onPressed: () => AddContactBottomSheet.show(
                      onAdd: controller.addContact,
                      onUpdate: controller.updateContact,
                      onSendInvite: controller.createCircleInvite,
                    ),
                    icon: const Icon(Icons.person_add_outlined, size: 16),
                    label: const Text('Add contact'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            final state = controller.screenState.value;

            if (state == GenericScreenStates.loading ||
                state == GenericScreenStates.initial) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }

            if (state == GenericScreenStates.error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: Dimensions.twelve,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.black26,
                    ),
                    Text(
                      'Could not load your circle',
                      style: context.theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            }

            final contacts = controller.contacts;

            if (contacts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: Dimensions.twelve,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Colors.black26,
                    ),
                    Text(
                      'No contacts in your circle yet',
                      style: context.theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    TextButton(
                      onPressed: () => AddContactBottomSheet.show(
                        onAdd: controller.addContact,
                        onUpdate: controller.updateContact,
                        onSendInvite: controller.createCircleInvite,
                      ),
                      child: const Text('Add your first contact'),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.twentyFour),
              itemCount: contacts.length,
              separatorBuilder: (_, _) => SizedBox(height: Dimensions.twelve),
              itemBuilder: (context, index) => ContactCard(
                contact: contacts[index],
                isInviting: controller.invitingContactId.value == contacts[index].id,
                onTap: () => AddContactBottomSheet.show(
                  onAdd: controller.addContact,
                  onUpdate: controller.updateContact,
                  onSendInvite: controller.createCircleInvite,
                  existingContact: contacts[index],
                ),
                onDelete: () => controller.deleteContact(contacts[index].id),
                onInvite: () async {
                  final contact = contacts[index];
                  final result = await controller.createCircleInvite(contactId: contact.id);
                  if (!result.isSuccess || result.data == null) {
                    Get.snackbar('Invite unavailable', result.error ?? 'The invite could not be created. Please try again.');
                    return;
                  }
                  AppBottomSheet.show(
                    context: context,
                    builder: (_) => InvitePickerSheet(
                      phone: contact.phone,
                      contactName: contact.name,
                      code: result.data!,
                      onRegenerate: () => controller.createCircleInvite(contactId: contact.id, regenerate: true),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}
