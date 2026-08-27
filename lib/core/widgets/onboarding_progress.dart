import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.completed,
    required this.total,
    required this.label,
  });

  final int completed;

  final int total;

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(Dimensions.twentyFour, Dimensions.sixteen, Dimensions.twentyFour, 0),
    child: Semantics(
      label: 'Setup progress',
      value: '$label. Step ${completed + 1} of $total.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(width: Dimensions.twelve),
                Text(
                  '$completed of $total done',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
                ),
              ],
            ),
            SizedBox(height: Dimensions.twelve),
            Row(
              spacing: Dimensions.eight,
              children: List<Widget>.generate(
                total,
                (int i) => Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < completed ? Colors.black : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

enum OnboardingStep {
  welcome('Welcome'),
  yourName('Your name'),
  emergencyContact('Emergency contact'),
  permissions('Permissions'),
  consent('Your privacy'),
  createAccount('Create account');

  const OnboardingStep(this.label);

  final String label;

  static int get total => OnboardingStep.values.length;

  int get completed => index;
}
