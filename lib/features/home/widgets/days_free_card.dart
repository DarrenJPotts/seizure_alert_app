import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class DaysFreeCard extends StatelessWidget {
  const DaysFreeCard({super.key, required this.days});

  final int? days;

  @override
  Widget build(BuildContext context) {
    final String headline;
    final String sub;

    if (days == null) {
      headline = '—';
      sub = 'No seizures logged yet';
    } else if (days == 0) {
      headline = 'Today';
      sub = 'Last seizure was today';
    } else if (days == 1) {
      headline = '1';
      sub = 'day since last seizure';
    } else {
      headline = '$days';
      sub = 'days since last seizure';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Dimensions.twentyFour),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Dimensions.eight,
        children: [
          const Text(
            'LAST SEIZURE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
