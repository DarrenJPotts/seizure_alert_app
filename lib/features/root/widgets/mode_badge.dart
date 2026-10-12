import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class ModeBadge extends StatefulWidget {
  const ModeBadge({
    super.key,
    required this.caregiver,
    required this.onTap,
    this.loading = false,
  });

  final bool caregiver;
  final VoidCallback onTap;
  final bool loading;

  @override
  State<ModeBadge> createState() => _ModeBadgeState();
}

class _ModeBadgeState extends State<ModeBadge> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String currentMode = widget.caregiver ? 'Caregiver' : 'Patient';
    final String nextMode = widget.caregiver ? 'patient' : 'caregiver';
    final bool enabled = !widget.loading;

    return Semantics(
      button: true,
      enabled: enabled,
      excludeSemantics: true,
      label: '$currentMode mode. Switch to $nextMode mode',
      onTap: enabled ? widget.onTap : null,
      child: Tooltip(
        message: 'Switch to $nextMode mode',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled
              ? (_) {
                  HapticFeedback.selectionClick();
                  _setPressed(true);
                }
              : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTap: enabled ? widget.onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: kMinInteractiveDimension,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.ten,
                  vertical: Dimensions.six,
                ),
                decoration: BoxDecoration(
                  color: _pressed ? scheme.inverseSurface : scheme.surface,
                  border: Border.all(
                    color: _pressed ? scheme.inverseSurface : scheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(Dimensions.circular),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (widget.loading)
                      SizedBox.square(
                        dimension: Dimensions.fourteen,
                        child: CircularProgressIndicator(
                          strokeWidth: Dimensions.two,
                          color: scheme.onSurface,
                        ),
                      )
                    else
                      Icon(
                        widget.caregiver
                            ? Icons.shield_outlined
                            : Icons.person_outline,
                        size: Dimensions.fourteen,
                        color: _pressed
                            ? scheme.onInverseSurface
                            : scheme.onSurface,
                      ),
                    SizedBox(width: Dimensions.six),
                    Text(
                      currentMode.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _pressed
                            ? scheme.onInverseSurface
                            : scheme.onSurface,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
