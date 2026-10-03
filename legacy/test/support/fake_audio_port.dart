import 'dart:async';
import 'package:quicksleep/audio/audio_port.dart';
import 'package:quicksleep/audio/audio_catalog.dart';
import 'package:quicksleep/session/session_plan.dart';

class FakeAudioPort implements AudioPort {
  final controller = StreamController<PortSnapshot>.broadcast(sync: true);
  final commands = <String>[];
  final loads = <List<AudioSegment>>[];
  Completer<void>? nextLoad;
  Completer<void>? nextStop;
  bool failLoad = false;
  int playCalls = 0, pauseCalls = 0, stopCalls = 0;
  @override
  Stream<PortSnapshot> get snapshots => controller.stream;
  @override
  Future<void> load(List<AudioSegment> segments, AudioCatalog catalog) async {
    commands.add('load');
    loads.add(segments);
    final gate = nextLoad;
    nextLoad = null;
    if (gate != null) await gate.future;
    if (failLoad) throw StateError('decoder failure');
  }

  @override
  Future<void> play() async {
    commands.add('play');
    playCalls++;
  }

  @override
  Future<void> pause() async {
    commands.add('pause');
    pauseCalls++;
  }

  @override
  Future<void> stop() async {
    commands.add('stop');
    stopCalls++;
    final gate = nextStop;
    nextStop = null;
    if (gate != null) await gate.future;
  }

  @override
  Future<void> dispose() async {
    await controller.close();
  }

  void emit({
    int index = 0,
    Duration position = Duration.zero,
    bool playing = true,
    bool completed = false,
    String? error,
  }) => controller.add(
    PortSnapshot(
      index: index,
      position: position,
      playing: playing,
      completed: completed,
      error: error,
    ),
  );
}

AudioCatalog fakeCatalog() => AudioCatalog([
  for (final l in ['zh', 'en'])
    for (final m in SoundMode.values)
      for (final role in ['guide', 'preview'])
        AudioAsset(
          id: '$l.${m.name}.$role',
          path: '$l/${m.name}_$role.wav',
          duration: Duration(seconds: role == 'guide' ? 80 : 8),
        ),
  for (final m in SoundMode.values)
    for (final role in ['bed', 'fade'])
      AudioAsset(
        id: 'shared.${m.name}.$role',
        path: 'beds/${m.name}_$role.wav',
        duration: Duration(seconds: role == 'bed' ? 60 : 15),
      ),
]);
