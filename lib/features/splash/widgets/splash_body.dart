import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class SplashBody extends StatelessWidget {
  const SplashBody({super.key, this.showProgress = true});

  final bool showProgress;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SplashMark(),
                  SizedBox(height: Dimensions.twentyEight),
                  Text(
                    'Seizure Alert',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: Dimensions.eight),
                  Text(
                    'Someone is always watching out',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: Colors.white.withValues(alpha: 0.5), letterSpacing: 0.2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SplashMark extends StatefulWidget {
  const _SplashMark();

  @override
  State<_SplashMark> createState() => _SplashMarkState();
}

class _SplashMarkState extends State<_SplashMark> with SingleTickerProviderStateMixin {
  static const double _size = 104;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _size,
    height: _size,
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext _, Widget? _) {
            final double t = Curves.easeOut.transform(_controller.value);
            return Transform.scale(
              scale: 0.5 + (1.1 * t),
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35 * (1 - t))),
                ),
              ),
            );
          },
        ),
        Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
          ),
          child: const Icon(Icons.emergency, color: Colors.white, size: 46),
        ),
      ],
    ),
  );
}
