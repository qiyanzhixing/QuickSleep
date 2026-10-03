enum SoundMode { moon, mountain, forest }

enum AppLanguage { zh, en }

enum BreathPhase { inhale, hold, exhale, transition, natural, fade, complete }

class SessionConfig {
  const SessionConfig({
    required this.minutes,
    required this.mode,
    required this.language,
  });
  final int minutes;
  final SoundMode mode;
  final AppLanguage language;
}

class AudioSegment {
  const AudioSegment({
    required this.assetId,
    required this.duration,
    this.sourceStart = Duration.zero,
  });
  final String assetId;
  final Duration sourceStart;
  final Duration duration;
}

class SessionPlan {
  SessionPlan(this.config, List<AudioSegment> segments)
    : segments = List.unmodifiable(segments);
  final SessionConfig config;
  final List<AudioSegment> segments;
  Duration get duration => Duration(minutes: config.minutes);
}

class SessionFrame {
  const SessionFrame({
    required this.phase,
    required this.elapsed,
    required this.remaining,
    this.cycle,
    this.count,
  });
  final BreathPhase phase;
  final int? cycle;
  final int? count;
  final Duration elapsed;
  final Duration remaining;
}

SessionPlan buildSessionPlan(SessionConfig config) {
  if (config.minutes < 2 || config.minutes > 60) {
    throw ArgumentError.value(
      config.minutes,
      'minutes',
      'Use 2–60 whole minutes',
    );
  }
  final mode = config.mode.name;
  return SessionPlan(config, [
    AudioSegment(
      assetId: '${config.language.name}.$mode.guide',
      duration: const Duration(seconds: 80),
    ),
    for (var i = 0; i < config.minutes - 2; i++)
      AudioSegment(
        assetId: 'shared.$mode.bed',
        duration: const Duration(seconds: 60),
      ),
    AudioSegment(
      assetId: 'shared.$mode.bed',
      duration: const Duration(seconds: 25),
    ),
    AudioSegment(
      assetId: 'shared.$mode.fade',
      duration: const Duration(seconds: 15),
    ),
  ]);
}

SessionFrame frameAt(SessionPlan plan, Duration position) {
  final elapsed = Duration(
    microseconds: position.inMicroseconds.clamp(
      0,
      plan.duration.inMicroseconds,
    ),
  );
  final seconds = elapsed.inSeconds;
  BreathPhase phase;
  int? cycle, count;
  if (elapsed >= plan.duration) {
    phase = BreathPhase.complete;
  } else if (elapsed >= plan.duration - const Duration(seconds: 15)) {
    phase = BreathPhase.fade;
  } else if (seconds >= 80) {
    phase = BreathPhase.natural;
  } else if (seconds >= 76) {
    phase = BreathPhase.transition;
  } else {
    cycle = seconds ~/ 19 + 1;
    final local = seconds % 19;
    if (local < 4) {
      phase = BreathPhase.inhale;
      count = local + 1;
    } else if (local < 11) {
      phase = BreathPhase.hold;
      count = local - 4 + 1;
    } else {
      phase = BreathPhase.exhale;
      count = local - 11 + 1;
    }
  }
  return SessionFrame(
    phase: phase,
    cycle: cycle,
    count: count,
    elapsed: elapsed,
    remaining: plan.duration - elapsed,
  );
}

Duration globalPosition(SessionPlan plan, int index, Duration localPosition) {
  if (index < 0) return Duration.zero;
  if (index >= plan.segments.length) return plan.duration;
  final before = plan.segments
      .take(index)
      .fold(Duration.zero, (sum, s) => sum + s.duration);
  final local = Duration(
    microseconds: localPosition.inMicroseconds.clamp(
      0,
      plan.segments[index].duration.inMicroseconds,
    ),
  );
  return before + local;
}
