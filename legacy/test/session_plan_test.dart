import 'package:flutter_test/flutter_test.dart';
import 'package:quicksleep/session/session_plan.dart';

SessionConfig config({int minutes = 10}) => SessionConfig(
  minutes: minutes,
  mode: SoundMode.moon,
  language: AppLanguage.zh,
);
void main() {
  test('all 2–60 minute plans have finite exact durations and four rounds', () {
    for (var minutes = 2; minutes <= 60; minutes++) {
      final plan = buildSessionPlan(config(minutes: minutes));
      expect(plan.duration, Duration(minutes: minutes));
      expect(
        plan.segments.fold(Duration.zero, (a, b) => a + b.duration),
        plan.duration,
      );
      expect(plan.segments.first.assetId, 'zh.moon.guide');
      expect(plan.segments.last.assetId, 'shared.moon.fade');
      expect(plan.segments.last.duration, const Duration(seconds: 15));
      expect(plan.segments.length, minutes + 1);
    }
  });
  test('phase boundaries and counts come from media time', () {
    final p = buildSessionPlan(config());
    final checks = {
      0: BreathPhase.inhale,
      3: BreathPhase.inhale,
      4: BreathPhase.hold,
      10: BreathPhase.hold,
      11: BreathPhase.exhale,
      18: BreathPhase.exhale,
      19: BreathPhase.inhale,
      75: BreathPhase.exhale,
      76: BreathPhase.transition,
      79: BreathPhase.transition,
      80: BreathPhase.natural,
      584: BreathPhase.natural,
      585: BreathPhase.fade,
      599: BreathPhase.fade,
      600: BreathPhase.complete,
    };
    for (final e in checks.entries) {
      expect(
        frameAt(p, Duration(seconds: e.key)).phase,
        e.value,
        reason: 'at ${e.key}',
      );
    }
    expect(frameAt(p, const Duration(seconds: 75)).cycle, 4);
    expect(frameAt(p, const Duration(seconds: 75)).count, 8);
    expect(frameAt(p, const Duration(seconds: 80)).count, isNull);
    expect(frameAt(p, const Duration(seconds: -1)).elapsed, Duration.zero);
    expect(frameAt(p, const Duration(seconds: 700)).remaining, Duration.zero);
  });
  test('global position stays continuous at all playlist boundaries', () {
    final p = buildSessionPlan(config());
    var offset = Duration.zero;
    for (var i = 0; i < p.segments.length; i++) {
      expect(globalPosition(p, i, Duration.zero), offset);
      offset += p.segments[i].duration;
      expect(globalPosition(p, i, p.segments[i].duration), offset);
    }
    expect(globalPosition(p, -4, Duration.zero), Duration.zero);
    expect(globalPosition(p, 999, const Duration(days: 1)), p.duration);
  });
  test('invalid duration cannot construct a plan', () {
    for (final n in [0, 1, 61, 100]) {
      expect(() => buildSessionPlan(config(minutes: n)), throwsArgumentError);
    }
  });
}
