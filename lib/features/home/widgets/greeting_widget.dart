import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class GreetingWidget extends StatelessWidget {
  const GreetingWidget({
    super.key,
    required this.greeting,
    required this.name,
  });

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
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.black54),
        ),
        if (name.isNotEmpty)
          Text(
            name,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}
