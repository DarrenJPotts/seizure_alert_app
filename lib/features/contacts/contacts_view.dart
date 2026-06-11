import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/invite_service.dart';
import 'package:seizure_app/features/contacts/view_models/contacts_view_model.dart';
import 'package:seizure_app/features/contacts/widgets/add_contact_bottom_sheet.dart';
import 'package:seizure_app/features/contacts/widgets/contact_card.dart';

class ContactsView extends GetView<ContactsViewModel> {
  const ContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.twentyFour,
            Dimensions.twentyFour,
            Dimensions.twentyFour,
            Dimensions.twelve,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Circle',
                  style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => AddContactBottomSheet.show(),
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Add contact'),
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
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.black26),
                    Text(
                      'Could not load your circle',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.black54),
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
                    const Icon(Icons.people_outline,
                        size: 48, color: Colors.black26),
                    Text(
                      'No contacts in your circle yet',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: () => AddContactBottomSheet.show(),
                      child: const Text('Add your first contact'),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding:
                  EdgeInsets.symmetric(horizontal: Dimensions.twentyFour),
              itemCount: contacts.length,
              separatorBuilder: (_, _) => SizedBox(height: Dimensions.twelve),
              itemBuilder: (context, index) => ContactCard(
                contact: contacts[index],
                onTap: () => AddContactBottomSheet.show(
                  existingContact: contacts[index],
                ),
                onDelete: () =>
                    controller.deleteContact(contacts[index].id),
                onInvite: () => InviteService.showInvitePicker(
                  phone: contacts[index].phone,
                  contactName: contacts[index].name,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
