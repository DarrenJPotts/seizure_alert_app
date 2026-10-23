import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../cycle/view_models/cycle_view_model.dart';
import '../view_models/seizure_log_view_model.dart';

Future<void> shareClinicalReport(
  BuildContext context,
  SeizureLogViewModel controller,
) async {
  HapticFeedback.selectionClick();
  CycleBinding().dependencies();
  final cycle = Get.find<CycleViewModel>();
  await cycle.load();
  if (!context.mounted) return;
  bool includeCycle = false;
  final available = cycle.data.value.enabled && cycle.error.value == null;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, update) => AlertDialog(
        scrollable: true,
        title: const Text('Share clinical report?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This report includes your recorded seizures and notes. Choose a trusted recipient. Shared copies can be kept or forwarded and cannot be recalled by deleting your account.',
            ),
            if (available)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include cycle data'),
                subtitle: const Text(
                  'Adds all recorded period dates, flow, symptoms and notes to the PDF and a separate CSV. Off by default.',
                ),
                value: includeCycle,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  update(() => includeCycle = value == true);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Share'),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final RenderBox? box = context.findRenderObject() as RenderBox?;
  final String? error = await controller.shareReport(
    includeCycleData: includeCycle,
    sharePositionOrigin: box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size,
  );
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}
