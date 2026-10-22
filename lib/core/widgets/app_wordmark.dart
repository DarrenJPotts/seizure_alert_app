import 'package:flutter/material.dart';
import '../themes/app_palette.dart';

/// Theme-aware typography replaces the logo image's opaque white background.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.width = 220});
  final double width;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Seizure Alert',
    image: true,
    child: ExcludeSemantics(
      child: SizedBox(
        width: width,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Seizure',
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
                const TextSpan(
                  text: 'Alert',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(color: context.ink),
          ),
        ),
      ),
    ),
  );
}
