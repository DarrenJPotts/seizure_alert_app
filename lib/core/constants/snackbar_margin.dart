import 'package:flutter/widgets.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

/// Keeps a bottom snackbar clear of the floating navigation bar.
///
/// That bar is 70px tall with a 20px margin, and the SOS control overhangs it
/// by a further 25 — so an unmargined bottom snackbar lands behind the one
/// control the user is most likely to be reaching for.
const EdgeInsets snackbarMargin = EdgeInsets.only(
  left: Dimensions.sixteen,
  right: Dimensions.sixteen,
  bottom: 104,
);
