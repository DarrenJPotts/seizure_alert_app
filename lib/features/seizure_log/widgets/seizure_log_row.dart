import 'package:flutter/material.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/widgets/settings/settings_group.dart';

class SeizureLogRow extends StatelessWidget {
  const SeizureLogRow({super.key, required this.log, required this.onTap});

  final SeizureLogDto log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String title = formatLogDate(log.occurredAt);
    final String subtitle = logSubtitle(log);

    return SettingsTileRow(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.06),
        ),
        child: const Icon(Icons.bolt, size: 20, color: Colors.black54),
      ),
      title: title,
      subtitle: subtitle,
      trailing: log.alertFired ? const SettingsTag('Alert sent') : null,
      onTap: onTap,
      semanticLabel: '$title. $subtitle.${log.alertFired ? ' Alert sent.' : ''}',
    );
  }
}

String formatLogDate(DateTime at, {DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  final DateTime today = DateTime(reference.year, reference.month, reference.day);
  final DateTime date = DateTime(at.year, at.month, at.day);
  final int days = today.difference(date).inDays;
  final String time = _formatTime(at);

  if (days == 0) return 'Today, $time';
  if (days == 1) return 'Yesterday, $time';
  return '${_monthAbbreviations[at.month - 1]} ${at.day}, $time';
}

String logSubtitle(SeizureLogDto log) {
  final List<String> parts = <String>[];

  final int? seconds = log.durationSeconds;
  if (seconds != null && seconds > 0) parts.add(formatLogDuration(seconds));

  final String? location = log.location;
  if (location != null && location.trim().isNotEmpty) parts.add(location.trim());

  return parts.isEmpty ? 'No details recorded' : parts.join(' · ');
}

String formatLogDuration(int totalSeconds) {
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  if (minutes == 0) return '~${seconds}s';
  if (seconds == 0) return '~${minutes}m';
  return '~${minutes}m ${seconds}s';
}

String formatLogMonth(DateTime at, {DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  if (at.year == reference.year && at.month == reference.month) return 'This month';
  if (at.year == reference.year) return _monthNames[at.month - 1];
  return '${_monthNames[at.month - 1]} ${at.year}';
}

String _formatTime(DateTime at) {
  final int raw = at.hour % 12;
  final int hour = raw == 0 ? 12 : raw;
  final String minute = at.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${at.hour >= 12 ? 'PM' : 'AM'}';
}

const List<String> _monthAbbreviations = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> _monthNames = <String>[
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
