import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicksleep/audio/session_audio_handler.dart';
import 'package:quicksleep/session/session_plan.dart';
import 'support/fake_audio_port.dart';

const config = SessionConfig(
  minutes: 10,
  mode: SoundMode.moon,
  language: AppLanguage.zh,
);
Future<void> flush() => Future<void>.delayed(Duration.zero);
void main() {
  late FakeAudioPort port;
  late SessionAudioHandler handler;
  setUp(() {
    port = FakeAudioPort();
    handler = SessionAudioHandler(port, fakeCatalog());
  });
  tearDown(() async {
    await handler.dispose();
  });
  test('latest start owns the queue and stale load never plays', () async {
    final gate = Completer<void>();
    port.nextLoad = gate;
    final first = handler.start(config);
    await flush();
    const second = SessionConfig(
      minutes: 5,
      mode: SoundMode.forest,
      language: AppLanguage.en,
    );
    final last = handler.start(second);
    gate.complete();
    await Future.wait([first, last]);
    expect(port.playCalls, 1);
    expect(handler.current.config, second);
    expect(port.loads.last.first.assetId, 'en.forest.guide');
  });
  test(
    'pause freezes actual media time and interruption end never resumes',
    () async {
      await handler.start(config);
      port.emit(position: const Duration(seconds: 30));
      await handler.pause();
      final remaining = handler.current.frame!.remaining;
      await flush();
      expect(handler.current.frame!.remaining, remaining);
      await handler.onInterruption(true);
      await handler.onInterruption(false);
      expect(port.playCalls, 1);
      expect(handler.current.status, SessionStatus.paused);
      await handler.play();
      expect(port.playCalls, 2);
    },
  );
  test('headphone disconnect pauses and requires manual resume', () async {
    await handler.start(config);
    await handler.onHeadphonesDisconnected();
    expect(port.pauseCalls, 1);
    expect(handler.current.status, SessionStatus.paused);
  });
  test('interruption during loading prevents delayed auto-play', () async {
    final gate = Completer<void>();
    port.nextLoad = gate;
    final start = handler.start(config);
    await flush();
    final interrupt = handler.onInterruption(true);
    gate.complete();
    await Future.wait([start, interrupt]);
    expect(port.playCalls, 0);
    expect(handler.current.status, SessionStatus.paused);
  });
  test(
    'starting a session stops preview and late sheet close leaves session playing',
    () async {
      await handler.preview(SoundMode.mountain, AppLanguage.en);
      final before = port.stopCalls;
      await handler.start(config);
      expect(port.stopCalls, greaterThan(before));
      final during = port.stopCalls;
      await handler.stopPreview();
      expect(port.stopCalls, during);
      expect(handler.current.config, config);
    },
  );
  test('preview close while loading cannot start stale audio', () async {
    final gate = Completer<void>();
    port.nextLoad = gate;
    final load = handler.preview(SoundMode.moon, AppLanguage.zh);
    await flush();
    final close = handler.stopPreview();
    gate.complete();
    await Future.wait([load, close]);
    expect(port.playCalls, 0);
  });
  test('stop during load invalidates pending playback', () async {
    final gate = Completer<void>();
    port.nextLoad = gate;
    final load = handler.start(config);
    await flush();
    final stop = handler.stop();
    gate.complete();
    await Future.wait([load, stop]);
    expect(port.playCalls, 0);
    expect(handler.current.status, SessionStatus.idle);
  });
  test(
    'finite completion stops once without replay and reports zero remaining',
    () async {
      await handler.start(config);
      port.emit(
        index: 10,
        position: const Duration(seconds: 15),
        completed: true,
      );
      await flush();
      expect(handler.current.status, SessionStatus.completed);
      expect(handler.current.frame!.remaining, Duration.zero);
      expect(port.playCalls, 1);
      expect(handler.playbackState.value.playing, false);
    },
  );
  test('load failure is visible and does not play', () async {
    port.failLoad = true;
    await handler.start(config);
    expect(handler.current.status, SessionStatus.error);
    expect(handler.current.error, isNotEmpty);
    expect(port.playCalls, 0);
  });
  test('decoder failure stops instead of advancing silently', () async {
    await handler.start(config);
    port.emit(error: 'bad source');
    await flush();
    expect(handler.current.status, SessionStatus.error);
    expect(port.stopCalls, greaterThan(1));
  });
  test('decoder cleanup cannot overlap a newer native load', () async {
    await handler.start(config);
    final gate = Completer<void>();
    port.nextStop = gate;
    port.emit(error: 'decode failed');
    await flush();
    final next = handler.start(
      const SessionConfig(
        minutes: 5,
        mode: SoundMode.forest,
        language: AppLanguage.en,
      ),
    );
    await flush();
    expect(
      port.loads.length,
      1,
      reason: 'New loads must wait for prior decoder cleanup',
    );
    gate.complete();
    await next;
    expect(port.loads.last.first.assetId, 'en.forest.guide');
    expect(handler.current.status, SessionStatus.playing);
  });
  test('lockscreen reports whole-session time and duration', () async {
    await handler.start(config);
    port.emit(index: 2, position: const Duration(seconds: 10));
    expect(
      handler.playbackState.value.updatePosition,
      const Duration(seconds: 150),
    );
    expect(handler.mediaItem.value!.duration, const Duration(minutes: 10));
    expect(handler.playbackState.value.controls.length, 2);
  });
}
