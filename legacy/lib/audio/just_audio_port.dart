import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../session/session_plan.dart';
import 'audio_catalog.dart';
import 'audio_port.dart';

class JustAudioPort implements AudioPort {
  JustAudioPort()
    : _player = AudioPlayer(
        handleInterruptions: false,
        useLazyPreparation: false,
        maxSkipsOnError: 0,
      ) {
    _subscriptions.add(_player.playbackEventStream.listen((_) => _emit()));
    _subscriptions.add(_player.positionStream.listen((_) => _emit()));
    _subscriptions.add(_player.playingStream.listen((_) => _emit()));
    _subscriptions.add(
      _player.errorStream.listen(
        (e) => _emit(error: e.message ?? e.code.toString()),
      ),
    );
  }
  final AudioPlayer _player;
  final _events = StreamController<PortSnapshot>.broadcast(sync: true);
  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _disposed = false;
  @override
  Stream<PortSnapshot> get snapshots => _events.stream;
  void _emit({String? error}) {
    if (_disposed) return;
    _events.add(
      PortSnapshot(
        index: _player.currentIndex ?? 0,
        position: _player.position,
        playing: _player.playing,
        completed: _player.processingState == ProcessingState.completed,
        buffering:
            _player.processingState == ProcessingState.loading ||
            _player.processingState == ProcessingState.buffering,
        error: error,
      ),
    );
  }

  @override
  Future<void> load(List<AudioSegment> segments, AudioCatalog catalog) async {
    await _player.setLoopMode(LoopMode.off);
    await _player.setShuffleModeEnabled(false);
    final sources = segments.map((s) {
      final asset = catalog.asset(s.assetId);
      if (s.sourceStart < Duration.zero ||
          s.sourceStart + s.duration > asset.duration) {
        throw StateError('Invalid clip: ${s.assetId}');
      }
      final source = AudioSource.asset(asset.path);
      return s.sourceStart == Duration.zero && s.duration == asset.duration
          ? source
          : ClippingAudioSource(
              child: source,
              start: s.sourceStart,
              end: s.sourceStart + s.duration,
              duration: s.duration,
            );
    }).toList();
    await _player.setAudioSources(
      sources,
      initialIndex: 0,
      initialPosition: Duration.zero,
    );
  }

  @override
  Future<void> play() async {
    // just_audio's play Future lasts until pause/completion. Observe failures,
    // but do not hold the serialized command queue for the session duration.
    unawaited(
      _player.play().catchError((Object e) {
        _emit(error: e.toString());
      }),
    );
  }

  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> dispose() async {
    _disposed = true;
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _player.dispose();
    await _events.close();
  }
}
