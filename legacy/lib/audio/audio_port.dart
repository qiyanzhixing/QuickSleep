import '../session/session_plan.dart';
import 'audio_catalog.dart';

class PortSnapshot {
  const PortSnapshot({
    required this.index,
    required this.position,
    required this.playing,
    this.completed = false,
    this.buffering = false,
    this.error,
  });
  final int index;
  final Duration position;
  final bool playing, completed, buffering;
  final String? error;
}

abstract interface class AudioPort {
  Stream<PortSnapshot> get snapshots;
  Future<void> load(List<AudioSegment> segments, AudioCatalog catalog);

  /// Resolves when play is requested, not when the entire playlist ends.
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> dispose();
}
