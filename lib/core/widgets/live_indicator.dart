import 'package:flutter/material.dart';

class LiveIndicator extends StatefulWidget {
  const LiveIndicator({
    super.key,
    this.size = 14,
    this.color = Colors.black,
    this.period = const Duration(milliseconds: 1800),
  });

  final double size;

  final Color color;

  final Duration period;

  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncToMotionPreference();
  }

  @override
  void didUpdateWidget(covariant LiveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.period != oldWidget.period) {
      _controller.duration = widget.period;
      _syncToMotionPreference();
    }
  }

  void _syncToMotionPreference() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
      return;
    }
    if (!_controller.isAnimating) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final double dotSize = widget.size * (6 / 14);

    return ExcludeSemantics(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (reduceMotion)
              _ring(scale: 1, opacity: 0.55)
            else
              AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext _, Widget? _) => _ring(
                  scale: 0.5 + (1.1 * Curves.easeOut.transform(_controller.value)),
                  opacity: 0.9 * (1 - _controller.value),
                ),
              ),
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring({required double scale, required double opacity}) => Transform.scale(
    scale: scale,
    child: Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: widget.color.withValues(alpha: 0.35 * opacity)),
      ),
    ),
  );
}

class LiveStatusLabel extends StatelessWidget {
  const LiveStatusLabel({
    super.key,
    required this.label,
    this.color = Colors.black,
    this.textStyle,
    this.indicatorSize = 14,
    this.gap = 8,
  });

  final String label;
  final Color color;
  final TextStyle? textStyle;
  final double indicatorSize;
  final double gap;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Live. $label',
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiveIndicator(size: indicatorSize, color: color),
          SizedBox(width: gap),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style:
                  textStyle ??
                  Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    ),
  );
}
