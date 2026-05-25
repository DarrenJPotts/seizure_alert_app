import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class StatusCardWidget extends StatelessWidget {
  const StatusCardWidget({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(Dimensions.twenty),
    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Dimensions.eight,
            children: [
              Text('Status', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
              Text(
                'Monitoring Active',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text('3 contacts in your circle', style: TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          ),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.greenAccent,
            boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)],
          ),
        ),
      ],
    ),
  );
}
