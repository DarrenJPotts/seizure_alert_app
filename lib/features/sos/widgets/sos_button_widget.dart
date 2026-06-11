import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Center(
                child: Text(
                  '$_remaining',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sending Alert...',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your emergency contacts will be notified in $_remaining second${_remaining == 1 ? '' : 's'}. Tap cancel to stop.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: _DialogButton(
                text: 'Cancel',
                onPressed: widget.onCancel,
              ),
            ),
          ],
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isPressed ? Colors.grey.shade100 : Colors.white,
          border: Border.all(color: Colors.black12, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            widget.text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
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
              style: TextStyle(
                fontSize: 11,
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
