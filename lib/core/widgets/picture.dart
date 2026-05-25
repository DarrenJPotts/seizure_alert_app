import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PictureWidget extends StatelessWidget {
  const PictureWidget({
    super.key,
    required this.imagePath,
    this.height,
    this.width,
    this.scale = 1.0,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final String imagePath;
  final double? height;
  final double? width;
  final BoxFit fit;
  final double scale;
  final AlignmentGeometry alignment;

  bool get isSvg => imagePath.endsWith('.svg');

  bool get isNetworkImage => imagePath.startsWith(RegExp('(http|https)'));

  @override
  Widget build(BuildContext context) {
    if (isNetworkImage) {
      if (isSvg) {
        return SvgPicture.network(
          imagePath,
          width: width,
          height: height,
          alignment: alignment,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => SizedBox.shrink(),
        );
      }

      return Image.network(
        imagePath,
        fit: fit,
        scale: scale,
        alignment: alignment,
        height: height,
        width: width,
        errorBuilder: (context, error, stackTrace) => SizedBox.shrink(),
      );
    }

    if (isSvg) {
      return SvgPicture.asset(
        imagePath,
        width: width,
        height: height,
        alignment: alignment,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => SizedBox.shrink(),
      );
    }

    return Image.asset(
      imagePath,
      fit: fit,
      scale: scale,
      alignment: alignment,
      height: height,
      width: width,
      errorBuilder: (context, error, stackTrace) => SizedBox.shrink(),
    );
  }
}
