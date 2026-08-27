import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class SettingsGroupHeader extends StatelessWidget {
  const SettingsGroupHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: Dimensions.two),
    child: Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: Colors.black.withValues(alpha: 0.4),
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
      color: Colors.white,
      border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) Divider(height: 1, thickness: 1, color: Colors.black.withValues(alpha: 0.1)),
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
        SizedBox(height: Dimensions.ten),
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
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: EdgeInsets.symmetric(horizontal: Dimensions.eighteen, vertical: Dimensions.fourteen),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 22, color: Colors.black),
          SizedBox(width: Dimensions.fourteen),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          SizedBox(width: Dimensions.twelve),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: valueColor ?? Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
          if (onTap != null) ...<Widget>[
            SizedBox(width: Dimensions.six),
            Icon(Icons.chevron_right, size: 20, color: Colors.black.withValues(alpha: 0.3)),
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
    final Widget row = SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Dimensions.sixteen),
        child: Row(
          children: <Widget>[
            if (leading != null) ...<Widget>[leading!, SizedBox(width: Dimensions.twelve)],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null) ...<Widget>[
                    SizedBox(height: Dimensions.two),
                    Text(
                      subtitle!,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[SizedBox(width: Dimensions.eight), trailing!],
            if (onTap != null) ...<Widget>[
              SizedBox(width: Dimensions.six),
              Icon(Icons.chevron_right, size: 20, color: Colors.black.withValues(alpha: 0.3)),
            ],
          ],
        ),
      ),
    );

    final Widget tappable = onTap == null ? row : InkWell(onTap: onTap, child: row);
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
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: subtitle == null ? title : '$title. $subtitle',
    child: ExcludeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: EdgeInsets.symmetric(horizontal: Dimensions.eighteen, vertical: Dimensions.sixteen),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 22, color: Colors.black),
              SizedBox(width: Dimensions.fourteen),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    if (subtitle != null) ...<Widget>[
                      SizedBox(height: Dimensions.two),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: Dimensions.twelve),
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
      color: value ? Colors.black : Colors.white,
      borderRadius: BorderRadius.circular(Dimensions.circular),
      border: value ? null : Border.all(color: Colors.black.withValues(alpha: 0.2), width: 1.5),
    ),
    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      width: value ? 24 : 22,
      height: value ? 24 : 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: value ? Colors.white : Colors.black.withValues(alpha: 0.25),
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
  });

  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      height: 64,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Dimensions.eighteen),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 22, color: Colors.black),
            SizedBox(width: Dimensions.fourteen),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText!,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            SizedBox(width: Dimensions.six),
            Icon(Icons.chevron_right, size: 20, color: Colors.black.withValues(alpha: 0.3)),
          ],
        ),
      ),
    ),
  );
}

class SettingsDestructiveRow extends StatelessWidget {
  const SettingsDestructiveRow({super.key, required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      height: 64,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Dimensions.eighteen),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 22, color: Colors.red.shade400),
            SizedBox(width: Dimensions.fourteen),
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
  const SettingsActionRow({super.key, required this.title, required this.onTap, this.badgeCount = 0});

  final String title;
  final VoidCallback onTap;

  final int badgeCount;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      height: 64,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Dimensions.sixteen),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(Icons.add, size: 18, color: Colors.black),
            ),
            SizedBox(width: Dimensions.twelve),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: Dimensions.eight, vertical: Dimensions.three),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(Dimensions.circular),
                ),
                child: Text(
                  '$badgeCount',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
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
    padding: EdgeInsets.symmetric(horizontal: Dimensions.eighteen, vertical: Dimensions.twenty),
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontSize: 14,
        height: 1.5,
        color: Colors.black.withValues(alpha: 0.45),
      ),
    ),
  );
}

class SettingsTag extends StatelessWidget {
  const SettingsTag(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: Dimensions.eight, vertical: Dimensions.three),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(Dimensions.circular),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Colors.black.withValues(alpha: 0.55),
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
