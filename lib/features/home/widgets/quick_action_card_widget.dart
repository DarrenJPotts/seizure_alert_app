import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color foreground = _isPressed ? context.paper : context.ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(context.design.cardRadius),
        onTapDown: (_) {
          setState(() => _isPressed = true);
          HapticFeedback.selectionClick();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeInOut,
          width: double.infinity,
          padding: EdgeInsets.all(context.design.cardPadding),
          decoration: BoxDecoration(
            color: _isPressed ? context.ink : context.cardSurface,
            border: context.designBorder,
            boxShadow: _isPressed ? const [] : context.designShadows,
            borderRadius: BorderRadius.circular(context.design.cardRadius),
          ),
          child: Column(
            spacing: Dimensions.eight,
            children: [
              Icon(widget.icon, size: Dimensions.twentyFour, color: foreground),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
