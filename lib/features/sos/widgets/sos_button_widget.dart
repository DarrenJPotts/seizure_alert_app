
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Minimal SOS Button Widget
class MinimalSOSButton extends StatefulWidget {
  final VoidCallback onPressed;

  const MinimalSOSButton({super.key, required this.onPressed});

  @override
  State<MinimalSOSButton> createState() => _MinimalSOSButtonState();
}

class _MinimalSOSButtonState extends State<MinimalSOSButton> {
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
        duration: Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPressed ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: _isPressed
              ? []
              : [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: Offset(0, 15))],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_outlined, size: 60, color: _isPressed ? Colors.white : Colors.black),
              SizedBox(height: 12),
              Text(
                'SOS',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 10,
                  color: _isPressed ? Colors.white : Colors.black,
                  height: 1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'TAP FOR HELP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                  color: _isPressed ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal Alert Dialog
class MinimalAlertDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const MinimalAlertDialog({required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Icon(Icons.touch_app_outlined, size: 40, color: Colors.black),
            ),

            SizedBox(height: 24),

            // Title
            Text(
              'Send Emergency Alert?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12),

            // Description
            Text(
              'Your emergency contacts will be notified immediately with your current location.',
              style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.6), height: 1.5),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: _MinimalButton(text: 'Cancel', onPressed: onCancel, isPrimary: false),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _MinimalButton(text: 'Send', onPressed: onConfirm, isPrimary: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimal Button for Dialog
class _MinimalButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _MinimalButton({required this.text, required this.onPressed, required this.isPrimary});

  @override
  State<_MinimalButton> createState() => _MinimalButtonState();
}

class _MinimalButtonState extends State<_MinimalButton> {
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
        duration: Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: widget.isPrimary
              ? (_isPressed ? Colors.grey.shade800 : Colors.black)
              : (_isPressed ? Colors.grey.shade100 : Colors.white),
          border: Border.all(
            color: widget.isPrimary ? Colors.black : Colors.grey.shade300,
            width: widget.isPrimary ? 0 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: widget.isPrimary ? Colors.white : Colors.black,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
