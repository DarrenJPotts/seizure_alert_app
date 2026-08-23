import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class SOSButton extends StatefulWidget {
  const SOSButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.heavyImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      // Outer focus ring
      child: Container(
        width: 264,
        height: 264,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeInOut,
            width: 208,
            height: 208,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isPressed ? Colors.black : Colors.white,
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: _isPressed
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                'SOS',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                  color: _isPressed ? Colors.white : Colors.black,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Countdown dialog — auto-sends after 5 seconds unless cancelled.
class CountdownAlertDialog extends StatefulWidget {
  const CountdownAlertDialog({
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  State<CountdownAlertDialog> createState() => _CountdownAlertDialogState();
}

class _CountdownAlertDialogState extends State<CountdownAlertDialog> {
  int _remaining = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remaining <= 1) {
        timer.cancel();
        widget.onConfirm();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (5 - _remaining) / 5;
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.twentyFour,
            Dimensions.twentyFour,
            Dimensions.twentyFour,
            Dimensions.twentyEight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SENDING SOS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                    ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_remaining',
                        style: const TextStyle(
                          fontSize: 160,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      SizedBox(height: Dimensions.twentyFour),
                      Text(
                        'Your circle is notified in $_remaining second${_remaining == 1 ? '' : 's'}.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.circular),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  SizedBox(height: Dimensions.twenty),
                  SizedBox(
                    width: double.infinity,
                    child: _DialogButton(
                      text: 'Cancel',
                      onPressed: widget.onCancel,
                    ),
                  ),
                  SizedBox(height: Dimensions.twelve),
                  Text(
                    'Do nothing and help is on the way',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatefulWidget {
  const _DialogButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(vertical: Dimensions.sixteen),
        decoration: BoxDecoration(
          color: _isPressed ? Colors.black : Colors.white,
          border: Border.all(
            color: _isPressed ? Colors.white24 : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            widget.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _isPressed ? Colors.white : Colors.black,
                  letterSpacing: 0.3,
                ),
          ),
        ),
      ),
    );
  }
}

/// Pulsing SOS circle shown while an SOS alert is active.
/// Two offset ripple rings expand outward from the inner circle and fade.
class PulsingSOSCircle extends StatefulWidget {
  const PulsingSOSCircle({super.key});

  @override
  State<PulsingSOSCircle> createState() => _PulsingSOSCircleState();
}

class _PulsingSOSCircleState extends State<PulsingSOSCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static double _easeOut(double t) => 1 - math.pow(1 - t, 2).toDouble();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final t1 = _controller.value;
        final t2 = (_controller.value + 0.5) % 1.0;
        return SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _Ring(progress: _easeOut(t1)),
              _Ring(progress: _easeOut(t2)),
              child!,
            ],
          ),
        );
      },
      child: Container(
        width: 208,
        height: 208,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SOS',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ACTIVE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final size = 208.0 + (80.0 * progress);
    final opacity = (1.0 - progress) * 0.18;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.black.withValues(alpha: opacity),
            width: 1.0,
          ),
        ),
      ),
    );
  }
}
