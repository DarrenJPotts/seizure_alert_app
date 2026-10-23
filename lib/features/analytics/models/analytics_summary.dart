import '../../../core/dtos/seizure_log_dto.dart';

class AnalyticsBucket {
  const AnalyticsBucket(this.label, this.count);
  final String label;
  final int count;
}

/// Descriptive statistics over the existing personal log, without predictions.
class AnalyticsSummary {
  AnalyticsSummary(
    Iterable<SeizureLogDto> records, {
    required DateTime now,
    required this.days,
  }) {
    if (days != 30 && days != 90) throw ArgumentError.value(days, 'days');
    final localNow = now.toLocal();
    end = localNow;
    start = DateTime(localNow.year, localNow.month, localNow.day - days + 1);
    previousStart = DateTime(start.year, start.month, start.day - days);
    current = [];
    var preceding = 0;
    for (final record in records) {
      final at = record.occurredAt.toLocal();
      if (at.isAfter(localNow) || at.isBefore(previousStart)) continue;
      if (at.isBefore(start)) {
        preceding++;
      } else {
        current.add(record);
      }
    }
    previousCount = preceding;
    final durations =
        current
            .map((entry) => entry.durationSeconds)
            .whereType<int>()
            .where((value) => value > 0)
            .toList()
          ..sort();
    final recovery =
        current
            .map((entry) => entry.recoveryMinutes)
            .whereType<int>()
            .where((value) => value >= 0)
            .toList()
          ..sort();
    durationCount = durations.length;
    recoveryCount = recovery.length;
    medianDurationSeconds = _median(durations);
    longestDurationSeconds = durations.isEmpty ? null : durations.last;
    medianRecoveryMinutes = _median(recovery);
    final binDays = days ~/ 6;
    final frequencyCounts = List.filled(6, 0);
    final timeCounts = List.filled(4, 0);
    final startCivil = DateTime.utc(start.year, start.month, start.day);
    for (final record in current) {
      final at = record.occurredAt.toLocal();
      final civil = DateTime.utc(at.year, at.month, at.day);
      final index = civil.difference(startCivil).inDays ~/ binDays;
      frequencyCounts[index]++;
      timeCounts[at.hour ~/ 6]++;
    }
    frequency = [
      for (var i = 0; i < 6; i++)
        AnalyticsBucket(
          '${shortDate(DateTime(start.year, start.month, start.day + i * binDays))} – ${shortDate(DateTime(start.year, start.month, start.day + (i + 1) * binDays - 1))}',
          frequencyCounts[i],
        ),
    ];
    const times = ['00:00–05:59', '06:00–11:59', '12:00–17:59', '18:00–23:59'];
    timeOfDay = [
      for (var i = 0; i < 4; i++) AnalyticsBucket(times[i], timeCounts[i]),
    ];
  }

  final int days;
  late final DateTime start;
  late final DateTime end;
  late final DateTime previousStart;
  late final List<SeizureLogDto> current;
  late final int previousCount;
  late final int durationCount;
  late final int recoveryCount;
  late final double? medianDurationSeconds;
  late final int? longestDurationSeconds;
  late final double? medianRecoveryMinutes;
  late final List<AnalyticsBucket> frequency;
  late final List<AnalyticsBucket> timeOfDay;

  int get count => current.length;
  String get comparison {
    if (previousCount == 0) {
      return 'No recorded events in the previous $days days';
    }
    final change = count - previousCount;
    if (change == 0) return 'Same recorded count as the previous $days days';
    return '${change.abs()} ${change > 0 ? 'more' : 'fewer'} recorded than the previous $days days';
  }

  static double? _median(List<int> values) {
    if (values.isEmpty) return null;
    final middle = values.length ~/ 2;
    return values.length.isOdd
        ? values[middle].toDouble()
        : (values[middle - 1] + values[middle]) / 2;
  }

  static String shortDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]}';
  }

  static String durationText(num? seconds) {
    if (seconds == null) return 'Not recorded';
    if (seconds < 60) {
      return '${seconds % 1 == 0 ? seconds.toInt() : seconds.toStringAsFixed(1)} sec';
    }
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainder = seconds % 60;
    return [
      if (hours > 0) '$hours hr',
      if (minutes > 0) '$minutes min',
      if (remainder > 0)
        '${remainder % 1 == 0 ? remainder.toInt() : remainder.toStringAsFixed(1)} sec',
    ].join(' ');
  }
}
