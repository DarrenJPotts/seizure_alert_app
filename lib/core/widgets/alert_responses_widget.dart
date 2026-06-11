import 'dart:async';

import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/alert_response_dto.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';

class AlertResponsesWidget extends StatefulWidget {
  const AlertResponsesWidget({super.key, required this.alertId});

  final String alertId;

  @override
  State<AlertResponsesWidget> createState() => _AlertResponsesWidgetState();
}

class _AlertResponsesWidgetState extends State<AlertResponsesWidget> {
  StreamSubscription<List<AlertResponseDto>>? _sub;
  List<AlertResponseDto> _responses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _sub = FirestoreService.instance()
        .watchAlertResponses(widget.alertId)
        .listen(
      (list) {
        if (mounted) {
          setState(() {
            _responses = list;
            _loading = false;
          });
        }
      },
      onError: (_) {
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your circle', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: Dimensions.twelve),
        if (_responses.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: Dimensions.eight),
            child: Text(
              'Waiting for your circle to respond...',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black45),
            ),
          )
        else
          Column(
            spacing: Dimensions.eight,
            children: _responses
                .map((r) => _ResponseRow(response: r))
                .toList(),
          ),
      ],
    );
  }
}

// ─── Response row ─────────────────────────────────────────────────────────────

class _ResponseRow extends StatelessWidget {
  const _ResponseRow({required this.response});

  final AlertResponseDto response;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Avatar ──────────────────────────────────────────────────────
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.06),
          ),
          child: Center(
            child: Text(
              _initials(response.contactName),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        SizedBox(width: Dimensions.twelve),

        // ── Name ────────────────────────────────────────────────────────
        Expanded(
          child: Text(
            response.contactName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),

        // ── Status badge ────────────────────────────────────────────────
        if (response.responding)
          _Badge(label: 'Responding', filled: true)
        else if (response.seen)
          _Badge(label: 'Seen', filled: false),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? Colors.black : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: filled ? Colors.white : Colors.black54,
            ),
      ),
    );
  }
}
