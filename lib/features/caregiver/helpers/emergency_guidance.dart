/// When a caregiver should call emergency services, as one line of copy.
///
/// The care plan says "call after N minutes". A caregiver in the middle of an
/// emergency should not have to do that arithmetic, so this gives the clock
/// time, how long is left, and says plainly once the time has passed.
String emergencyCallGuidance({
  required DateTime startedAt,
  required int callAfterMinutes,
  required DateTime now,
  required String Function(DateTime) formatTime,
}) {
  final String started = 'Started ${formatTime(startedAt)}.';
  if (callAfterMinutes <= 0) {
    return '$started Call emergency services if you are worried.';
  }

  final DateTime deadline = startedAt.add(Duration(minutes: callAfterMinutes));
  final Duration left = deadline.difference(now);
  if (left <= Duration.zero) {
    return '$started It is past ${formatTime(deadline)}. '
        'Call emergency services now.';
  }

  final String mm = left.inMinutes.toString();
  final String ss = left.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$started Call emergency services at ${formatTime(deadline)} '
      '($mm:$ss left) unless the plan says sooner.';
}

/// True once the care plan's wait has run out.
bool isPastEmergencyDeadline({
  required DateTime startedAt,
  required int callAfterMinutes,
  required DateTime now,
}) {
  if (callAfterMinutes <= 0) return false;
  return !now.isBefore(startedAt.add(Duration(minutes: callAfterMinutes)));
}
