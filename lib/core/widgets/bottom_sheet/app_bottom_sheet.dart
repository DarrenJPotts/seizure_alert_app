import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class AppBottomSheet {
  const AppBottomSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double? radius,
  }) => showModalBottomSheet<T>(
    context: context,
    backgroundColor: context.paper,
    useSafeArea: true,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(
          radius ?? context.design.featureRadius + Dimensions.eight,
        ),
      ),
    ),
    builder: builder,
  );
}

class AppBottomSheetHandle extends StatelessWidget {
  const AppBottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: Dimensions.thirtySix,
      height: 4,
      decoration: BoxDecoration(
        color: context.ink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class AppBottomSheetContent extends StatelessWidget {
  const AppBottomSheetContent({
    super.key,
    required this.child,
    this.scrollable = true,
  });

  final Widget child;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // The keyboard already covers the navigation area. Reserve the larger
    // obstruction rather than adding both and leaving a second empty strip.
    final bottomInset = media.viewInsets.bottom > media.viewPadding.bottom
        ? media.viewInsets.bottom
        : media.viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(top: Dimensions.twelve),
              child: AppBottomSheetHandle(),
            ),
            const SizedBox(height: Dimensions.twelve),
            Flexible(
              child: scrollable
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        Dimensions.twentyFour,
                        0,
                        Dimensions.twentyFour,
                        Dimensions.twentyFour,
                      ),
                      child: child,
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Dimensions.twentyFour,
                        0,
                        Dimensions.twentyFour,
                        Dimensions.twentyFour,
                      ),
                      child: child,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
