DateTime dailyDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);
String dailyDateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

class DailyLogDto {
  const DailyLogDto({
    required this.date,
    this.sleepMinutes,
    this.sleepQuality,
    this.mood,
    this.stress,
    this.sideEffects = '',
    this.notes = '',
    this.noSeizuresReported = false,
    this.revision = 0,
    this.updatedAt,
  });
  final DateTime date;
  final int? sleepMinutes;
  final String? sleepQuality;
  final String? mood;
  final String? stress;
  final String sideEffects;
  final String notes;
  final bool noSeizuresReported;
  final int revision;
  final DateTime? updatedAt;
  static const qualities = {'poor': 'Poor', 'fair': 'Fair', 'good': 'Good'};
  static const moods = {'low': 'Low', 'neutral': 'Neutral', 'good': 'Good'};
  static const stresses = {
    'low': 'Low',
    'moderate': 'Moderate',
    'high': 'High',
  };
  bool get hasDetails =>
      sleepMinutes != null ||
      sleepQuality != null ||
      mood != null ||
      stress != null ||
      sideEffects.isNotEmpty ||
      notes.isNotEmpty ||
      noSeizuresReported;
  String? validate(DateTime today) {
    if (date.year < 1900 || dailyDate(date).isAfter(dailyDate(today))) {
      return 'Choose today or an earlier date.';
    }
    if (sleepMinutes != null && (sleepMinutes! < 0 || sleepMinutes! > 1440)) {
      return 'Enter sleep between 0 and 24 hours.';
    }
    if (sleepQuality != null && !qualities.containsKey(sleepQuality) ||
        mood != null && !moods.containsKey(mood) ||
        stress != null && !stresses.containsKey(stress)) {
      return 'Choose one of the listed options.';
    }
    if (sideEffects.length > 200 || notes.length > 500) {
      return 'Shorten the side effects or notes.';
    }
    if (!hasDetails) {
      return 'Record at least one detail, or remove the existing daily entry.';
    }
    return null;
  }

  DailyLogDto saved(int nextRevision, DateTime at) => DailyLogDto(
    date: dailyDate(date),
    sleepMinutes: sleepMinutes,
    sleepQuality: sleepQuality,
    mood: mood,
    stress: stress,
    sideEffects: sideEffects,
    notes: notes,
    noSeizuresReported: noSeizuresReported,
    revision: nextRevision,
    updatedAt: at.toUtc(),
  );
  Map<String, dynamic> toMap() => {
    'date': dailyDateKey(date),
    'sleepMinutes': sleepMinutes,
    'sleepQuality': sleepQuality,
    'mood': mood,
    'stress': stress,
    'sideEffects': sideEffects,
    'notes': notes,
    'noSeizuresReported': noSeizuresReported,
    'revision': revision,
    'updatedAt': updatedAt?.toUtc().toIso8601String(),
  };
  factory DailyLogDto.fromMap(Map<String, dynamic> map) {
    final date = DateTime.parse(map['date'] as String);
    if (dailyDateKey(date) != map['date']) {
      throw const FormatException('Invalid daily date');
    }
    return DailyLogDto(
      date: date,
      sleepMinutes: map['sleepMinutes'] as int?,
      sleepQuality: map['sleepQuality'] as String?,
      mood: map['mood'] as String?,
      stress: map['stress'] as String?,
      sideEffects: map['sideEffects'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      noSeizuresReported: map['noSeizuresReported'] as bool? ?? false,
      revision: map['revision'] as int? ?? 0,
      updatedAt: map['updatedAt'] == null
          ? null
          : DateTime.parse(map['updatedAt'] as String),
    );
  }
}
