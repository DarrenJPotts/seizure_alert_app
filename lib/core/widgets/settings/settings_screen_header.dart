import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class SettingsScreenHeader extends StatelessWidget {
  const SettingsScreenHeader({
    super.key,
    required this.title,
    this.backLabel,
    this.onBack,
    this.trailing,
  });

  final String title;

  final String? backLabel;
  final VoidCallback? onBack;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    assert(
      (backLabel == null) == (onBack == null),
      'backLabel and onBack must be supplied together',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.twenty,
        Dimensions.eight,
        Dimensions.twenty,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (backLabel != null) ...<Widget>[
            GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: Semantics(
                button: true,
                label: 'Back to $backLabel',
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: context.secondaryInk,
                      ),
                      const SizedBox(width: Dimensions.six),
                      Text(
                        backLabel!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: context.secondaryInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: Dimensions.ten),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(height: 1.1),
                ),
              ),
              ?trailing,
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsScreenPlaceholder extends StatelessWidget {
  const SettingsScreenPlaceholder({
    super.key,
    required this.icon,
    required this.message,
    this.detail,
    this.action,
  });

  final IconData icon;
  final String message;
  final String? detail;
  final Widget? action;

  Widget? _detailText(BuildContext context) => detail == null
      ? null
      : Text(
          detail!,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
        );

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Dimensions.twentyFour),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Dimensions.twelve,
        children: <Widget>[
          Icon(icon, size: 48, color: context.ink.withValues(alpha: 0.26)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.secondaryInk),
          ),
          ?_detailText(context),
          ?action,
        ],
      ),
    ),
  );
}
