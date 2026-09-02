import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/widgets/live_indicator.dart';
import 'package:seizure_app/features/sos/view_models/sos_view_model.dart';

/// Black status-board header shown at the top of the active-SOS screen.
/// Shows a live "SOS ACTIVE" indicator, elapsed time, a segmented
/// seen-indicator, and an "X of Y contacts have seen this" caption.
class SosStatusBoardHeader extends StatelessWidget {
  const SosStatusBoardHeader({
    super.key,
    required this.elapsedLabel,
    required this.seenCount,
    required this.totalCount,
    required this.onCancel,
    required this.delivery,
    required this.onCallForHelp,
  });

  final String elapsedLabel;
  final int seenCount;
  final int totalCount;
  final VoidCallback onCancel;
  final SosDelivery delivery;

  /// Escape hatch shown when the alert has not reached anyone.
  final VoidCallback onCallForHelp;

  bool get _undelivered => delivery == SosDelivery.queued || delivery == SosDelivery.failed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: EdgeInsets.fromLTRB(
        Dimensions.twentyFour,
        Dimensions.sixteen,
        Dimensions.twentyFour,
        Dimensions.twenty,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _StatusLabel(delivery: delivery)),
              _CancelButton(onCancel: onCancel),
            ],
          ),
          SizedBox(height: Dimensions.sixteen),
          Text(
            elapsedLabel,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              height: 1,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(height: Dimensions.twenty),
          if (_undelivered)
            _UndeliveredNotice(delivery: delivery, onCallForHelp: onCallForHelp)
          else ...<Widget>[
            Row(
              children: List.generate(totalCount == 0 ? 1 : totalCount, (i) {
                final filled = i < seenCount;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i == (totalCount == 0 ? 0 : totalCount - 1) ? 0 : Dimensions.four),
                    height: 4,
                    decoration: BoxDecoration(
                      color: filled ? Colors.white : Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(Dimensions.circular),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: Dimensions.twelve),
            Text(
              totalCount == 0 ? 'No contacts to notify' : '$seenCount of $totalCount contacts have seen this',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.delivery});

  final SosDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 3);

    return switch (delivery) {
      // Only a confirmed send gets the live indicator. Pulsing "live" at
      // someone whose alert is stuck in a queue is the lie this screen used
      // to tell.
      SosDelivery.delivered => Row(
        children: <Widget>[
          const LiveIndicator(size: 12, color: Colors.white),
          SizedBox(width: Dimensions.eight),
          Expanded(child: Text('SOS ACTIVE', style: style)),
        ],
      ),
      SosDelivery.sending => Row(
        children: <Widget>[
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          SizedBox(width: Dimensions.eight),
          Expanded(child: Text('SENDING…', style: style)),
        ],
      ),
      SosDelivery.queued || SosDelivery.failed => Row(
        children: <Widget>[
          const Icon(Icons.cloud_off, size: 14, color: Colors.white),
          SizedBox(width: Dimensions.eight),
          Expanded(child: Text('NOT SENT', style: style)),
        ],
      ),
    };
  }
}

/// The single most consequential control in the app.
///
/// Was a bare `Text` in a `GestureDetector` — roughly 50x20, no confirmation,
/// no haptic. One mis-tap by a post-ictal user stood the whole circle down
/// silently. Removing a *contact* asks for confirmation; calling off an
/// emergency did not.
class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Cancel this alert',
    child: ExcludeSemantics(
      child: TextButton(
        onPressed: () => _confirm(context),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          // 48px minimum target.
          minimumSize: const Size(88, 48),
          padding: EdgeInsets.symmetric(horizontal: Dimensions.sixteen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.circular),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
          ),
        ),
        child: Text(
          'Cancel',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );

  Future<void> _confirm(BuildContext context) async {
    HapticFeedback.heavyImpact();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Cancel this alert?"),
        content: const Text(
          'Your circle will be told you are OK and will stop responding. '
          'Only do this if you no longer need help.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep alert active'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
            child: const Text('Cancel alert'),
          ),
        ],
      ),
    );

    if (confirmed == true) onCancel();
  }
}

/// Shown in place of the seen-indicator when nothing has reached the server.
///
/// The seen-indicator is meaningless here — nobody can have seen an alert that
/// was never sent — so it is replaced rather than sitting alongside, and the
/// only action offered is the one that still works without a network.
class _UndeliveredNotice extends StatelessWidget {
  const _UndeliveredNotice({required this.delivery, required this.onCallForHelp});

  final SosDelivery delivery;
  final VoidCallback onCallForHelp;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(Dimensions.sixteen),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          delivery == SosDelivery.queued
              ? 'No connection — nobody has been notified yet. This will send by itself as soon as you are back online.'
              : 'This alert could not be sent. Nobody has been notified.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white, height: 1.5, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: Dimensions.fourteen),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onCallForHelp,
            icon: const Icon(Icons.call, size: 20),
            label: const Text('Call a contact instead'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    ),
  );
}
