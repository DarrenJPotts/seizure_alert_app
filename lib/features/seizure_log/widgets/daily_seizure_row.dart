import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/dtos/seizure_log_dto.dart';
import '../../../core/themes/app_palette.dart';
import 'seizure_log_row.dart';

class DailySeizureRow extends StatelessWidget {
  const DailySeizureRow({
    super.key,
    required this.log,
    required this.onTap,
    required this.onDelete,
  });

  final SeizureLogDto log;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey<String>(log.id),
    direction: DismissDirection.endToStart,
    background: ColoredBox(
      color: Colors.red.shade50,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: Dimensions.twenty),
          child: Icon(Icons.delete_outline, color: Colors.red.shade400),
        ),
      ),
    ),
    confirmDismiss: (DismissDirection _) async {
      HapticFeedback.selectionClick();
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          backgroundColor: context.paper,
          title: const Text('Remove this entry?'),
          content: const Text(
            'It will be permanently deleted from your seizure log.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirmed != true) return false;
      return onDelete();
    },
    child: SeizureLogRow(log: log, onTap: onTap),
  );
}
