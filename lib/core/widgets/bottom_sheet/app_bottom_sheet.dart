import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

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
