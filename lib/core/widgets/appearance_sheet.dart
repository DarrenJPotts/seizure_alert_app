import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/controllers/theme_controller/theme_controller.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';
import 'bottom_sheet/app_bottom_sheet.dart';

class AppearanceSettingsRow extends StatelessWidget {
  const AppearanceSettingsRow({super.key});

  static String label(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance();
    return Obx(
      () => SettingsNavRow(
        icon: Icons.contrast,
        title: 'Appearance',
        trailingText: label(controller.themeMode.value),
        onTap: () => AppBottomSheet.show<void>(
          context: context,
          builder: (_) => const AppearanceSheet(),
        ),
      ),
    );
  }
}

class AppearanceSheet extends StatelessWidget {
  const AppearanceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance();
    return AppBottomSheetContent(
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Dimensions.twelve),
            for (final mode in [
              ThemeMode.system,
              ThemeMode.light,
              ThemeMode.dark,
            ])
              ListTile(
                title: Text(AppearanceSettingsRow.label(mode)),
                subtitle: mode == ThemeMode.system
                    ? const Text('Follow your device appearance')
                    : null,
                trailing: controller.themeMode.value == mode
                    ? const Icon(Icons.check)
                    : null,
                selected: controller.themeMode.value == mode,
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.setThemeMode(mode);
                },
              ),
            const SizedBox(height: Dimensions.twelve),
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
