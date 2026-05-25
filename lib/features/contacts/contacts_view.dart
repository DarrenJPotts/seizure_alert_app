import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class ContactsView extends StatelessWidget {
  const ContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> mockContacts = [
      {'name': 'Sarah Johnson', 'relation': 'Sister', 'phone': '+27 82 123 4567'},
      {'name': 'Dr. Patel', 'relation': 'Neurologist', 'phone': '+27 11 555 0192'},
    ];

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
              Text('My Circle', style: Theme
                  .of(context)
                  .textTheme
                  .titleMedium),
              TextButton.icon(
                onPressed: () {},
                icon: Icon(Icons.person_add_outlined, size: 16),
                label: Text('Add contact'),
              ),
            ],
          ),
        ),
        Expanded(
          child: mockContacts.isEmpty
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: Dimensions.twelve,
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.black26),
                Text('No contacts added yet'),
                TextButton(onPressed: () {}, child: Text('Add your first contact')),
              ],
            ),
          )
              : ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: Dimensions.twentyFour),
            itemCount: mockContacts.length,
            separatorBuilder: (_, __) => SizedBox(height: Dimensions.twelve),
            itemBuilder: (context, index) {
              final contact = mockContacts[index];
              return _ContactCard(
                name: contact['name']!,
                relation: contact['relation']!,
                phone: contact['phone']!,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name;
  final String relation;
  final String phone;

  const _ContactCard({required this.name, required this.relation, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Dimensions.sixteen),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.black,
            child: Text(
              name.substring(0, 1),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: Dimensions.twelve),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(name, style: Theme.of(context).textTheme.bodyMedium),
                Text('$relation · $phone', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.black26),
        ],
      ),
    );
  }
}