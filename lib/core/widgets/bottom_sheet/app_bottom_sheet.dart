import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

/// Shows a bottom sheet with the app's standard chrome: white background,
/// safe-area aware, scroll-controlled, rounded top corners.
class AppBottomSheet {
  const AppBottomSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double radius = Dimensions.twentyFour,
  }) => showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.white,
    useSafeArea: true,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
    ),
    builder: builder,
  );
}

/// The 36x4 drag handle centred at the top of every bottom sheet.
class AppBottomSheetHandle extends StatelessWidget {
  const AppBottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: Dimensions.thirtySix,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

/// Standard bottom sheet body: keyboard-avoiding padding, the drag handle,
/// and [child] laid out below it with `Dimensions.twentyFour` padding on all
/// sides. Wrap [child] in a `Form` if the sheet needs validation.
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
    final body = Padding(
      padding: EdgeInsets.all(Dimensions.twentyFour),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBottomSheetHandle(),
          SizedBox(height: Dimensions.twentyFour),
          child,
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: scrollable ? SingleChildScrollView(child: body) : body,
    );
  }
}
