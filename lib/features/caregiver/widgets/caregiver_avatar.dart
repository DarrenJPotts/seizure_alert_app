import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CaregiverAvatar extends StatelessWidget {
  const CaregiverAvatar({
    super.key,
    required this.name,
    this.size = 34,
    this.background = Colors.black,
    this.foreground = Colors.white,
  });

  final String? name;
  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final String resolved = name ?? FirebaseAuth.instance.currentUser?.displayName ?? '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: background),
      alignment: Alignment.center,
      child: Text(
        initialsOf(resolved),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: size * (11 / 34),
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

String initialsOf(String value) {
  final List<String> parts = value.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}
