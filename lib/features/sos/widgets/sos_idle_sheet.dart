import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class SosIdleSheet extends StatefulWidget {
  const SosIdleSheet({
    super.key,
    required this.sosHero,
    required this.content,
    required this.sheetMinSize,
    required this.sheetMaxSize,
    this.onOpenHeadsUp,
  });

  final Widget sosHero;
  final Widget content;
  final double sheetMinSize;
  final double sheetMaxSize;
  final Future<void> Function()? onOpenHeadsUp;

  @override
  State<SosIdleSheet> createState() => _SosIdleSheetState();
}

class _SosIdleSheetState extends State<SosIdleSheet> {
  late final DraggableScrollableController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController()
      ..addListener(_onExtentChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onExtentChanged);
    _controller.dispose();
    super.dispose();
  }

  double _collapsedExtent = 0.1;
  bool _openingHeadsUp = false;

  bool get _isRevealed =>
      widget.onOpenHeadsUp == null &&
      _controller.isAttached &&
      _controller.size > _collapsedExtent + 0.02;

  void _onExtentChanged() {
    if (widget.onOpenHeadsUp != null &&
        _controller.isAttached &&
        _controller.size > _collapsedExtent + 0.02) {
      _openMainDrawer();
    }
  }

  void _openMainDrawer() {
    final open = widget.onOpenHeadsUp;
    if (_openingHeadsUp || open == null) return;
    _openingHeadsUp = true;
    // Extent changes happen during layout. Push the modal after that frame,
    // keeping one route open even while the original drag is still moving.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      HapticFeedback.selectionClick();
      if (_controller.isAttached) _controller.jumpTo(_collapsedExtent);
      try {
        await open();
      } finally {
        if (mounted) {
          if (_controller.isAttached) _controller.jumpTo(_collapsedExtent);
          _openingHeadsUp = false;
        }
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _toggleSheet() {
    if (!_controller.isAttached) return;
    if (widget.onOpenHeadsUp != null) {
      _openMainDrawer();
      return;
    }
    HapticFeedback.selectionClick();
    final target = _isRevealed ? _collapsedExtent : widget.sheetMaxSize;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpTo(target);
    } else {
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        _collapsedExtent = constraints.maxHeight > 0
            ? (widget.sheetMinSize + bottomInset / constraints.maxHeight).clamp(
                widget.sheetMinSize,
                widget.sheetMaxSize,
              )
            : widget.sheetMinSize;
        final sheetMinHeight = constraints.maxHeight * _collapsedExtent;

        return Stack(
          children: [
            Positioned.fill(
              bottom: sheetMinHeight,
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.twentyFour),
                child: Center(
                  child: SingleChildScrollView(child: widget.sosHero),
                ),
              ),
            ),
            DraggableScrollableSheet(
              controller: _controller,
              initialChildSize: _collapsedExtent,
              minChildSize: _collapsedExtent,
              maxChildSize: widget.sheetMaxSize,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        Dimensions.twentyFour,
                        Dimensions.eight,
                        Dimensions.twentyFour,
                        Dimensions.twentyFour,
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: Dimensions.thirtySix,
                              height: 4,
                              margin: const EdgeInsets.only(
                                bottom: Dimensions.four,
                              ),
                              decoration: BoxDecoration(
                                color: context.ink.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  Dimensions.circular,
                                ),
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: Dimensions.eight,
                              ),
                              child: Semantics(
                                key: const ValueKey('heads-up-sheet-toggle'),
                                button: true,
                                label: 'Heads Up',
                                value: _isRevealed ? 'Expanded' : 'Collapsed',
                                hint: widget.onOpenHeadsUp != null
                                    ? 'Open Heads Up drawer'
                                    : _isRevealed
                                    ? 'Collapse controls'
                                    : 'Expand controls',
                                onTap: _toggleSheet,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  excludeFromSemantics: true,
                                  onTap: _toggleSheet,
                                  child: ExcludeSemantics(
                                    child: SizedBox(
                                      height: _isRevealed
                                          ? null
                                          : (sheetMinHeight -
                                                    bottomInset -
                                                    Dimensions.twentyFour)
                                                .clamp(0.0, double.infinity),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: child,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.keyboard_arrow_up,
                                  size: 18,
                                  color: context.secondaryInk,
                                ),
                                const SizedBox(width: Dimensions.six),
                                Text(
                                  'Heads Up',
                                  key: const ValueKey('heads-up-sheet-heading'),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: context.secondaryInk,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: context.ink.withValues(alpha: 0.12),
                          ),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) =>
                                _isRevealed ? child! : const SizedBox.shrink(),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: Dimensions.twentyFour,
                              ),
                              child: widget.content,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
