import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';

class SeizureLogCard extends StatelessWidget {
  const SeizureLogCard({super.key, required this.log, required this.onTap});

  final SeizureLogDto log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(Dimensions.sixteen),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.06),
              ),
              child: const Icon(Icons.bolt, size: 20, color: Colors.black54),
            ),
            SizedBox(width: Dimensions.twelve),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(_formatDate(log.occurredAt),
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    _subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black45),
                  ),
                ],
              ),
            ),
            if (log.alertFired)
              Container(
                margin: EdgeInsets.only(right: Dimensions.eight),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Alert sent',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.black54),
                ),
              ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  String get _subtitle {
    final parts = <String>[];
    final dur = log.durationSeconds;
    if (dur != null && dur > 0) parts.add(_formatDuration(dur));
    final loc = log.location;
    if (loc != null && loc.isNotEmpty) parts.add(loc);
    return parts.isEmpty ? 'No details recorded' : parts.join(' · ');
  }

  String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    if (m == 0) return '~${s}s';
    if (s == 0) return '~${m}m';
    return '~${m}m ${s}s';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;
    final time = _formatTime(dt);
    if (diff == 0) return 'Today, $time';
    if (diff == 1) return 'Yesterday, $time';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, $time';
  }

  String _formatTime(DateTime dt) {
    final raw = dt.hour % 12;
    final h = raw == 0 ? 12 : raw;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}
