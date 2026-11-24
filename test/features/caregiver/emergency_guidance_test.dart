import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/features/caregiver/helpers/emergency_guidance.dart';

void main() {
  String hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  final DateTime start = DateTime(2026, 11, 23, 14, 2);

  test('gives the clock time and the time left', () {
    expect(
      emergencyCallGuidance(
        startedAt: start,
        callAfterMinutes: 5,
        now: start.add(const Duration(minutes: 1, seconds: 48)),
        formatTime: hhmm,
      ),
      'Started 14:02. Call emergency services at 14:07 (3:12 left) '
      'unless the plan says sooner.',
    );
  });

  test('says to call now once the time has passed', () {
    expect(
      emergencyCallGuidance(
        startedAt: start,
        callAfterMinutes: 5,
        now: start.add(const Duration(minutes: 5)),
        formatTime: hhmm,
      ),
      'Started 14:02. It is past 14:07. Call emergency services now.',
    );
    expect(
      isPastEmergencyDeadline(
        startedAt: start,
        callAfterMinutes: 5,
        now: start.add(const Duration(minutes: 5)),
      ),
      isTrue,
    );
  });

  test('never says "after 0 minutes"', () {
    final String line = emergencyCallGuidance(
      startedAt: start,
      callAfterMinutes: 0,
      now: start,
      formatTime: hhmm,
    );
    expect(line, 'Started 14:02. Call emergency services if you are worried.');
    expect(
      isPastEmergencyDeadline(
        startedAt: start,
        callAfterMinutes: 0,
        now: start,
      ),
      isFalse,
    );
  });
}
