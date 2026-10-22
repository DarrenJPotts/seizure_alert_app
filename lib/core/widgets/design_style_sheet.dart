import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/dimensions.dart';
import '../controllers/theme_controller/theme_controller.dart';
import '../themes/app_palette.dart';
import 'appearance_sheet.dart';
import 'bottom_sheet/app_bottom_sheet.dart';

class DesignVersionFooter extends StatefulWidget {
  const DesignVersionFooter({super.key});

  @override
  State<DesignVersionFooter> createState() => _DesignVersionFooterState();
}

class _DesignVersionFooterState extends State<DesignVersionFooter> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final enabled = ThemeController.instance().designSwitcherEnabled;
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (context, snapshot) {
        final info = snapshot.data;
        final version = info == null
            ? 'Seizure Alert'
            : 'Version ${info.version} (${info.buildNumber})';
        return Semantics(
          button: enabled,
          hint: enabled ? 'Long press to change design style' : null,
          child: InkWell(
            key: const ValueKey('design-version-footer'),
            onLongPress: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    DesignStyleSheet.show(context);
                  }
                : null,
            borderRadius: BorderRadius.circular(context.design.cardRadius),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: Dimensions.fortyEight,
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(Dimensions.twelve),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: Dimensions.four,
                children: [
                  Text(version, style: Theme.of(context).textTheme.bodySmall),
                  if (enabled)
                    Text(
                      'Hold to change design style',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class DesignStyleSheet extends StatelessWidget {
  const DesignStyleSheet({super.key});

  static Future<void> show(BuildContext context) async {
    if (!ThemeController.instance().designSwitcherEnabled) return;
    await AppBottomSheet.show<void>(
      context: context,
      builder: (_) => const DesignStyleSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance();
    if (!controller.designSwitcherEnabled) return const SizedBox.shrink();
    return AppBottomSheetContent(
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Dimensions.twelve,
          children: [
            Text(
              'Design style',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Development preview · applies immediately',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final style in AppDesignStyle.values)
              ListTile(
                key: ValueKey('design-${style.name}'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.twelve,
                  vertical: Dimensions.four,
                ),
                title: Text(style.label),
                subtitle: Text(style.description),
                selected: controller.resolvedDesign == style,
                selectedColor: context.ink,
                selectedTileColor: context.ink.withValues(alpha: 0.06),
                trailing: controller.resolvedDesign == style
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.setDesignStyle(style);
                },
              ),
            const Divider(),
            Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: Dimensions.eight,
              runSpacing: Dimensions.eight,
              children: [
                for (final mode in ThemeMode.values)
                  ChoiceChip(
                    label: Text(AppearanceSettingsRow.label(mode)),
                    selected: controller.themeMode.value == mode,
                    selectedColor: context.ink,
                    backgroundColor: context.paper,
                    checkmarkColor: context.paper,
                    labelStyle: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(
                          color: controller.themeMode.value == mode
                              ? context.paper
                              : context.ink,
                        ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      controller.setThemeMode(mode);
                    },
                  ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
