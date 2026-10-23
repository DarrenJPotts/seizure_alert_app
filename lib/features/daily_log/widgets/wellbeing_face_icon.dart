import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/themes/app_palette.dart';

/// Local vector faces; the adjacent choice label supplies the accessible name.
class WellbeingFaceIcon extends StatelessWidget {
  const WellbeingFaceIcon({
    super.key,
    required this.category,
    required this.value,
  });
  final String category;
  final String? value;

  String get _features {
    if (value == null) {
      return '<path d="M10 16h12"/>';
    }
    return switch ((category, value)) {
      ('Sleep quality', 'poor') =>
        '<path d="m9 11 4 2m6 0 4-2M10 17h3m6 0h3M11 23q5-5 10 0"/>',
      ('Sleep quality', 'fair') =>
        '<path d="M9 14q2 2 4 0m6 0q2 2 4 0M12 22h8"/>',
      ('Sleep quality', 'good') =>
        '<path d="M9 14q2 3 4 0m6 0q2 3 4 0M11 20q5 6 10 0"/>',
      ('Mood', 'low') => '<path d="M11 14v2m10-2v2M11 23q5-6 10 0"/>',
      ('Mood', 'neutral') => '<path d="M11 14v2m10-2v2M12 22h8"/>',
      ('Mood', 'good') =>
        '<path d="M9 14q2-3 4 0m6 0q2-3 4 0M10 20q6 8 12 0"/>',
      ('Stress', 'low') =>
        '<path d="M9 14q2 2 4 0m6 0q2 2 4 0M12 21q4 4 8 0"/>',
      ('Stress', 'moderate') =>
        '<path d="m9 11 4 1m6 0 4-1M11 15v2m10-2v2M12 23q4-3 8-1"/>',
      ('Stress', 'high') =>
        '<path d="m9 11 4 2m6 0 4-2m-14 3 4 2-4 2m14-4-4 2 4 2M11 24q5-6 10 0"/>',
      _ => '<path d="M11 14v2m10-2v2M12 22h8"/>',
    };
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" fill="none" stroke="black" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="16" cy="16" r="13"/>$_features</svg>',
      width: Dimensions.thirtySix,
      height: Dimensions.thirtySix,
      colorFilter: ColorFilter.mode(context.ink, BlendMode.srcIn),
    ),
  );
}
