import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

VoidCallback? _tap(VoidCallback? onTap) => onTap == null
    ? null
    : () {
        HapticFeedback.selectionClick();
        onTap();
      };

class SettingsGroupHeader extends StatelessWidget {
  const SettingsGroupHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Dimensions.two),
    child: Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: context.secondaryInk,
      ),
    ),
  );
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.design.filledCards || context.design.raisedSurfaces
          ? context.cardSurface
          : context.paper,
      border: context.designBorder,
      boxShadow: context.designShadows,
      borderRadius: BorderRadius.circular(context.design.featureRadius),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0)
            Divider(
              height: 1,
              thickness: 1,
              color: context.ink.withValues(alpha: 0.1),
            ),
          children[i],
        ],
      ],
    ),
  );
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, this.label, required this.children});

  final String? label;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      if (label != null) ...<Widget>[
        SettingsGroupHeader(label!),
        const SizedBox(height: Dimensions.ten),
      ],
      SettingsGroup(children: children),
    ],
  );
}

class SettingsValueRow extends StatelessWidget {
  const SettingsValueRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: loading ? null : _tap(onTap),
    child: Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.eighteen,
        vertical: Dimensions.fourteen,
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 22, color: context.ink),
          const SizedBox(width: Dimensions.fourteen),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final labelStyle = Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500);
                final valueStyle = Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: valueColor ?? context.secondaryInk);
                double textWidth(String text, TextStyle? style) {
                  final painter = TextPainter(
                    text: TextSpan(text: text, style: style),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                  )..layout();
                  final width = painter.width;
                  painter.dispose();
                  return width;
                }

                final inline =
                    !label.contains('\n') &&
                    !value.contains('\n') &&
                    textWidth(label, labelStyle) +
                            Dimensions.twelve +
                            (loading
                                ? Dimensions.sixteen
                                : textWidth(value, valueStyle)) <=
                        constraints.maxWidth;
                final valueWidget = loading
                    ? SizedBox.square(
                        dimension: Dimensions.sixteen,
                        child: CircularProgressIndicator(
                          color: context.ink,
                          strokeWidth: 1.5,
                        ),
                      )
                    : Text(value, style: valueStyle);
                if (!loading && value.isEmpty) {
                  return Text(label, style: labelStyle);
                }
                if (inline) {
                  return Row(
                    children: [
                      Expanded(child: Text(label, style: labelStyle)),
                      const SizedBox(width: Dimensions.twelve),
                      valueWidget,
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: labelStyle),
                    const SizedBox(height: Dimensions.four),
                    valueWidget,
                  ],
                );
              },
            ),
          ),
          if (onTap != null && !loading) ...<Widget>[
            const SizedBox(width: Dimensions.six),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: context.ink.withValues(alpha: 0.3),
            ),
          ],
        ],
      ),
    ),
  );
}

class SettingsTileRow extends StatelessWidget {
  const SettingsTileRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.height = 70,
    this.semanticLabel,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double height;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.sixteen,
          vertical: Dimensions.twelve,
        ),
        child: Row(
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading!,
              const SizedBox(width: Dimensions.twelve),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: Dimensions.two),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 13,
                        color: context.secondaryInk,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: Dimensions.eight),
              trailing!,
            ],
            if (onTap != null) ...<Widget>[
              const SizedBox(width: Dimensions.six),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: context.ink.withValues(alpha: 0.3),
              ),
            ],
          ],
        ),
      ),
    );

    final Widget tappable = onTap == null
        ? row
        : InkWell(onTap: _tap(onTap), child: row);
    if (semanticLabel == null) return tappable;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: ExcludeSemantics(child: tappable),
    );
  }
}

class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool loading;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: subtitle == null ? title : '$title. $subtitle',
    child: ExcludeSemantics(
      child: InkWell(
        onTap: loading
            ? null
            : () {
                HapticFeedback.selectionClick();
                onChanged(!value);
              },
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.eighteen,
            vertical: Dimensions.sixteen,
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 22, color: context.ink),
              const SizedBox(width: Dimensions.fourteen),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: Dimensions.two),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 13,
                          color: context.secondaryInk,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Dimensions.twelve),
              if (loading)
                SizedBox.square(
                  dimension: Dimensions.twenty,
                  child: CircularProgressIndicator(
                    color: context.ink,
                    strokeWidth: 1.5,
                  ),
                )
              else
                _ModeToggle(value: value),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    curve: Curves.easeInOut,
    width: 52,
    height: 30,
    padding: const EdgeInsets.symmetric(horizontal: 3),
    decoration: BoxDecoration(
      color: value ? context.ink : context.paper,
      borderRadius: BorderRadius.circular(Dimensions.circular),
      border: value
          ? null
          : Border.all(color: context.ink.withValues(alpha: 0.2), width: 1.5),
    ),
    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      width: value ? 24 : 22,
      height: value ? 24 : 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: value ? context.paper : context.ink.withValues(alpha: 0.25),
      ),
    ),
  );
}

class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) => SettingsValueRow(
    icon: icon,
    label: title,
    value: trailingText ?? '',
    onTap: onTap,
    loading: loading,
  );
}

class SettingsDestructiveRow extends StatelessWidget {
  const SettingsDestructiveRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () {
      HapticFeedback.heavyImpact();
      onTap();
    },
    child: SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.eighteen),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 22, color: Colors.red.shade400),
            const SizedBox(width: Dimensions.fourteen),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SettingsActionRow extends StatelessWidget {
  const SettingsActionRow({
    super.key,
    required this.title,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String title;
  final VoidCallback onTap;

  final int badgeCount;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: _tap(onTap),
    child: SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.sixteen),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.ink.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(Icons.add, size: 18, color: context.ink),
            ),
            const SizedBox(width: Dimensions.twelve),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.eight,
                  vertical: Dimensions.three,
                ),
                decoration: BoxDecoration(
                  color: context.ink,
                  borderRadius: BorderRadius.circular(Dimensions.circular),
                ),
                child: Text(
                  '$badgeCount',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.paper,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class SettingsMessageRow extends StatelessWidget {
  const SettingsMessageRow(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: Dimensions.eighteen,
      vertical: Dimensions.twenty,
    ),
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontSize: 14,
        height: 1.5,
        color: context.secondaryInk,
      ),
    ),
  );
}

class SettingsTag extends StatelessWidget {
  const SettingsTag(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: Dimensions.eight,
      vertical: Dimensions.three,
    ),
    decoration: BoxDecoration(
      color: context.ink.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(Dimensions.circular),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: context.secondaryInk,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
