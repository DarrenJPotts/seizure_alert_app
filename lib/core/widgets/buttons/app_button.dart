import 'package:flutter/material.dart';

import 'button_styles/base_button_style.dart';

class AppButton extends StatefulWidget {
  const AppButton({
    required this.buttonStyle,
    required this.buttonText,
    this.enabled = true,
    this.onTap,
    this.buttonWidth,
    this.buttonHeight = 48,
    this.disabledOnTap,
    this.leadingWidget,
    this.trailingWidget,
    this.isLoading,
    super.key,
  });

  final BaseButtonStyle buttonStyle;
  final String buttonText;
  final VoidCallback? onTap;
  final VoidCallback? disabledOnTap;
  final bool enabled;
  final double? buttonWidth;
  final double? buttonHeight;
  final bool? isLoading;
  final Widget? leadingWidget;
  final Widget? trailingWidget;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovering = false;

  void _onHover(bool value) => setState(() {
    _isHovering = value;
  });

  /// `NOTE`: We want to remove the border width from the hover padding,
  /// so that the button does not change its size when hovered.
  EdgeInsetsGeometry get _calculateHoverBorderWidth {
    try {
      double horizontalPadding = widget.buttonStyle.padding.horizontal == 0
          ? widget.buttonStyle.padding.horizontal
          : widget.buttonStyle.padding.horizontal -
                widget.buttonStyle.borderHoverWidth;
      double verticalPadding = widget.buttonStyle.padding.vertical == 0
          ? widget.buttonStyle.padding.vertical
          : widget.buttonStyle.padding.vertical -
                widget.buttonStyle.borderHoverWidth;

      if (widget.buttonStyle.padding.horizontal >=
              widget.buttonStyle.borderHoverWidth &&
          widget.buttonStyle.padding.vertical >=
              widget.buttonStyle.borderHoverWidth) {
        // Ensure that the padding does not go negative
        if (horizontalPadding < 0) {
          horizontalPadding = 0;
        }
        if (verticalPadding < 0) {
          verticalPadding = 0;
        }
      }

      return EdgeInsets.only(
        left: horizontalPadding / 2,
        right: horizontalPadding / 2,
        top: verticalPadding / 2,
        bottom: verticalPadding / 2,
      );
    } catch (e) {
      return widget.buttonStyle.padding;
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onHover: (value) => _onHover(value),
      hoverColor: widget.enabled == true
          ? widget.buttonStyle.hoverColor
          : widget.buttonStyle.disabledHoverColor,
      borderRadius: widget.buttonStyle.borderRadius,
      onTap: () => widget.isLoading == true
          ? null
          : widget.enabled == true
          ? widget.onTap?.call()
          : widget.disabledOnTap?.call(),
      child: Ink(
        width: widget.buttonWidth,
        height: widget.buttonHeight,
        decoration: _boxDecoration,
        child: Padding(
          padding: _isHovering
              ? _calculateHoverBorderWidth
              : widget.buttonStyle.padding,
          child: _buttonContent(context: context),
        ),
      ),
    ),
  );

  Widget _buttonContent({required BuildContext context}) {
    if (widget.isLoading == true) {
      return _buildButtonLoadingContent(context: context);
    } else {
      return _buildButtonContent(context: context);
    }
  }

  Widget _buildButtonLoadingContent({required BuildContext context}) => Center(
    child: SizedBox(
      width: widget.buttonStyle.loaderHeight,
      height: widget.buttonStyle.loaderWidth,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.enabled == true
              ? widget.buttonStyle.loaderColor
              : widget.buttonStyle.disabledLoaderColor,
        ),
        backgroundColor: widget.enabled == true
            ? widget.buttonStyle.loaderBackgroundColor
            : widget.buttonStyle.disabledLoaderBackgroundColor,
      ),
    ),
  );

  Widget _buildButtonContent({required BuildContext context}) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      widget.leadingWidget ?? const SizedBox.shrink(),
      Expanded(
        child: Text(
          widget.buttonText,
          style: widget.enabled == true
              ? widget.buttonStyle.textStyle
              : widget.buttonStyle.disabledTextStyle,
          textAlign: widget.buttonStyle.textAlign,
          maxLines: widget.buttonStyle.maxLines,
          overflow: widget.buttonStyle.textOverflow,
        ),
      ),
      widget.trailingWidget ?? const SizedBox.shrink(),
    ],
  );

  BoxDecoration get _boxDecoration => BoxDecoration(
    color: widget.enabled == true
        ? widget.buttonStyle.buttonColor
        : widget.buttonStyle.disabledColor,
    borderRadius: widget.buttonStyle.borderRadius,
    border: Border.all(
      color: widget.enabled == true
          ? widget.buttonStyle.borderColor
          : widget.buttonStyle.disabledBorderColor,
      width: _isHovering
          ? widget.buttonStyle.borderHoverWidth
          : widget.buttonStyle.borderWidth,
    ),
  );
}
