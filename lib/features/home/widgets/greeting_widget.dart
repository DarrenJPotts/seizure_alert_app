import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class GreetingWidget extends StatelessWidget {
  const GreetingWidget({super.key, required this.greeting, required this.name});

  final String greeting;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Dimensions.four,
      children: [
        Text(
          name.isEmpty ? greeting : '$greeting,',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: context.secondaryInk),
        ),
        if (name.isNotEmpty)
          Text(
            name,
            style: context.design.greetingStyle(Theme.of(context).textTheme),
          ),
      ],
    );
  }
}
