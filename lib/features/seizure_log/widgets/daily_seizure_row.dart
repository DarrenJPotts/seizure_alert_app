import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
      color: Theme.of(context).colorScheme.errorContainer,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: Dimensions.twenty),
          child: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    ),
    confirmDismiss: (DismissDirection _) => _confirmAndDelete(context),
    child: Semantics(
      customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
        const CustomSemanticsAction(label: 'Remove entry'): () =>
            _confirmAndDelete(context),
      },
      child: Row(
        children: <Widget>[
          Expanded(
            child: SeizureLogRow(log: log, onTap: onTap),
          ),
          // Swiping is not the only way to remove an entry.
          IconButton(
            onPressed: () => _confirmAndDelete(context),
            tooltip: 'Remove entry',
            icon: Icon(Icons.delete_outline, color: context.secondaryInk),
          ),
        ],
      ),
    ),
  );

  Future<bool> _confirmAndDelete(BuildContext context) async {
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    return onDelete();
  }
}
