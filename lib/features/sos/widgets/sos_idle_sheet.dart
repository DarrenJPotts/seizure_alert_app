import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class SosIdleSheet extends StatefulWidget {
  const SosIdleSheet({
    super.key,
    required this.sosHero,
    required this.content,
    required this.sheetMinSize,
    required this.sheetMaxSize,
  });

  final Widget sosHero;
  final Widget content;
  final double sheetMinSize;
  final double sheetMaxSize;

  @override
  State<SosIdleSheet> createState() => _SosIdleSheetState();
}

class _SosIdleSheetState extends State<SosIdleSheet> {
  late final DraggableScrollableController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _collapsedExtent = 0.1;

  bool get _isRevealed =>
      _controller.isAttached && _controller.size > _collapsedExtent + 0.02;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = Theme.of(context).textTheme.bodySmall;
        final labelHeight =
            MediaQuery.textScalerOf(
              context,
            ).scale(style?.fontSize ?? Dimensions.fourteen) *
            (style?.height ?? 1.4);
        final minimumHeight =
            Dimensions.sixteen +
            Dimensions.four +
            Dimensions.twelve +
            labelHeight +
            Dimensions.twelve +
            Dimensions.two +
            Dimensions.twentyFour;
        _collapsedExtent = (minimumHeight / constraints.maxHeight).clamp(
          widget.sheetMinSize,
          widget.sheetMaxSize,
        );
        final sheetMinHeight = constraints.maxHeight * _collapsedExtent;

        return Stack(
          children: [
            Positioned.fill(
              bottom: sheetMinHeight,
              child: Padding(
                padding: EdgeInsets.all(Dimensions.twentyFour),
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
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      Dimensions.twentyFour,
                      Dimensions.sixteen,
                      Dimensions.twentyFour,
                      Dimensions.twentyFour,
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: Dimensions.thirtySix,
                            height: 4,
                            margin: EdgeInsets.only(bottom: Dimensions.twelve),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(
                                Dimensions.circular,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: Dimensions.twelve),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.keyboard_arrow_up,
                                size: 18,
                                color: Colors.black.withValues(alpha: 0.45),
                              ),
                              SizedBox(width: Dimensions.six),
                              Text(
                                'Heads Up',
                                key: const ValueKey('heads-up-sheet-heading'),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.black.withValues(
                                        alpha: 0.55,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 1,
                          color: Colors.black12,
                        ),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) =>
                              _isRevealed ? child! : const SizedBox.shrink(),
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: Dimensions.twentyFour,
                            ),
                            child: widget.content,
                          ),
                        ),
                      ],
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
