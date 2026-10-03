import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import '../session/session_plan.dart';
import '../l10n/generated/app_localizations.dart';
import 'audio_catalog.dart';
import 'audio_port.dart';

enum SessionStatus { idle, loading, playing, paused, completed, error }

class SessionSnapshot {
  const SessionSnapshot({
    this.config,
    this.frame,
    this.status = SessionStatus.idle,
    this.error,
  });
  final SessionConfig? config;
  final SessionFrame? frame;
  final SessionStatus status;
  final String? error;
}

class PreviewSnapshot {
  const PreviewSnapshot({this.mode, this.error});
  final SoundMode? mode;
  final String? error;
}

/// One owner for foreground, preview, lock-screen and interruption commands.
/// All native mutations are serialized; request IDs invalidate work immediately.
class SessionAudioHandler extends BaseAudioHandler {
  SessionAudioHandler(this._port, this._catalog) {
    _subscriptions.add(
      _port.snapshots.listen(
        _onSnapshot,
        onError: (Object error) => _handlePortError(error),
      ),
    );
  }
  final AudioPort _port;
  final AudioCatalog _catalog;
  final _states = BehaviorSubject<SessionSnapshot>.seeded(
    const SessionSnapshot(),
  );
  final _previews = BehaviorSubject<PreviewSnapshot>.seeded(
    const PreviewSnapshot(),
  );
  final _subscriptions = <StreamSubscription<dynamic>>[];
  Future<void> _commands = Future.value();
  SessionPlan? _plan;
  int _request = 0;
  bool _acceptSnapshots = false, _wantPlayback = false, _disposed = false;
  SoundMode? _previewMode;
  ValueStream<SessionSnapshot> get sessionStates => _states.stream;
  ValueStream<PreviewSnapshot> get previewStates => _previews.stream;
  SessionSnapshot get current => _states.value;

  Future<void> connectInterruptions(AudioSession session) async {
    await session.configure(const AudioSessionConfiguration.music());
    _subscriptions.add(
      session.interruptionEventStream.listen((event) {
        unawaited(onInterruption(event.begin));
      }),
    );
    _subscriptions.add(
      session.becomingNoisyEventStream.listen((_) {
        unawaited(onHeadphonesDisconnected());
      }),
    );
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _commands.catchError((Object _) {}).then((_) async {
      if (!_disposed) await action();
    });
    _commands = next;
    return next;
  }

  String _modeName(AppLocalizations l, SoundMode mode) => switch (mode) {
    SoundMode.moon => l.modeMoon,
    SoundMode.mountain => l.modeMountain,
    SoundMode.forest => l.modeForest,
  };
  void _metadata(SessionConfig config, {bool preview = false}) {
    final l = lookupAppLocalizations(Locale(config.language.name));
    final item = MediaItem(
      id: preview ? 'preview' : 'session',
      title: _modeName(l, config.mode),
      artist: preview ? l.preview : l.sessionTitle,
      duration: preview
          ? const Duration(seconds: 8)
          : Duration(minutes: config.minutes),
    );
    mediaItem.add(item);
    queue.add([item]);
  }

  Future<void> start(SessionConfig config) async {
    final plan = buildSessionPlan(config);
    final request = ++_request;
    _acceptSnapshots = false;
    _wantPlayback = true;
    _previewMode = null;
    _previews.add(const PreviewSnapshot());
    _plan = plan;
    _metadata(config);
    _publish(SessionStatus.loading, frameAt(plan, Duration.zero));
    await _enqueue(() async {
      if (request != _request) return;
      try {
        await _port.stop();
        if (request != _request) return;
        await _port.load(plan.segments, _catalog);
        if (request != _request) return;
        _acceptSnapshots = true;
        _publish(
          _wantPlayback ? SessionStatus.playing : SessionStatus.paused,
          frameAt(plan, Duration.zero),
        );
        if (_wantPlayback) await _port.play();
      } catch (e) {
        await _fail(request, e);
      }
    });
  }

  @override
  Future<void> play() async {
    if (_plan == null ||
        ![
          SessionStatus.paused,
          SessionStatus.loading,
        ].contains(current.status)) {
      return;
    }
    _wantPlayback = true;
    final request = _request;
    await _enqueue(() async {
      if (request != _request ||
          !_wantPlayback ||
          !_acceptSnapshots ||
          current.status == SessionStatus.playing) {
        return;
      }
      try {
        await _port.play();
        _publish(SessionStatus.playing, current.frame);
      } catch (e) {
        await _fail(request, e);
      }
    });
  }

  @override
  Future<void> pause() async {
    if (_previewMode != null) {
      await stopPreview();
      return;
    }
    if (_plan == null ||
        ![
          SessionStatus.loading,
          SessionStatus.playing,
          SessionStatus.paused,
        ].contains(current.status)) {
      return;
    }
    _wantPlayback = false;
    final request = _request;
    _publish(SessionStatus.paused, current.frame);
    await _enqueue(() async {
      if (request == _request) {
        try {
          await _port.pause();
        } catch (e) {
          await _fail(request, e);
        }
      }
    });
  }

  @override
  Future<void> stop() async {
    final request = ++_request;
    _acceptSnapshots = false;
    _wantPlayback = false;
    _plan = null;
    _previewMode = null;
    _previews.add(const PreviewSnapshot());
    _publish(SessionStatus.idle, null);
    await _enqueue(() async {
      if (request == _request) {
        try {
          await _port.stop();
        } catch (_) {
          /* Already visibly stopped. */
        }
      }
    });
  }

  Future<void> preview(SoundMode mode, AppLanguage language) async {
    // Preview cannot replace a currently active relaxation session.
    if (_plan != null &&
        [
          SessionStatus.loading,
          SessionStatus.playing,
          SessionStatus.paused,
        ].contains(current.status)) {
      return;
    }
    final request = ++_request;
    _plan = null;
    _previewMode = mode;
    _wantPlayback = true;
    _acceptSnapshots = false;
    _previews.add(PreviewSnapshot(mode: mode));
    _metadata(
      SessionConfig(minutes: 2, mode: mode, language: language),
      preview: true,
    );
    await _enqueue(() async {
      if (request != _request) return;
      try {
        await _port.stop();
        if (request != _request) return;
        await _port.load([
          AudioSegment(
            assetId: '${language.name}.${mode.name}.preview',
            duration: const Duration(seconds: 8),
          ),
        ], _catalog);
        if (request != _request) return;
        _acceptSnapshots = true;
        playbackState.add(
          PlaybackState(
            controls: [MediaControl.stop],
            processingState: AudioProcessingState.ready,
            playing: true,
          ),
        );
        await _port.play();
      } catch (e) {
        await _fail(request, e);
      }
    });
  }

  Future<void> stopPreview() async {
    if (_previewMode != null) await stop();
  }

  Future<void> onInterruption(bool began) async {
    if (began) await pause();
  }

  Future<void> onHeadphonesDisconnected() => pause();
  void _handlePortError(Object error) {
    if (!_acceptSnapshots || _disposed) return;
    final request = _request;
    _acceptSnapshots = false;
    unawaited(_enqueue(() => _fail(request, error)));
  }

  void _onSnapshot(PortSnapshot value) {
    if (!_acceptSnapshots || _disposed) return;
    if (value.error != null) {
      _handlePortError(value.error!);
      return;
    }
    if (_previewMode != null) {
      if (value.completed) unawaited(stopPreview());
      return;
    }
    final plan = _plan;
    if (plan == null) return;
    if (value.completed) {
      final request = _request;
      _wantPlayback = false;
      _acceptSnapshots = false;
      _publish(SessionStatus.completed, frameAt(plan, plan.duration));
      unawaited(
        _enqueue(() async {
          if (request == _request) await _port.stop();
        }),
      );
      return;
    }
    final frame = frameAt(
      plan,
      globalPosition(plan, value.index, value.position),
    );
    final status = value.playing && _wantPlayback
        ? SessionStatus.playing
        : SessionStatus.paused;
    _publish(status, frame, buffering: value.buffering);
  }

  void _publish(
    SessionStatus status,
    SessionFrame? frame, {
    String? error,
    bool buffering = false,
  }) {
    if (_disposed) return;
    _states.add(
      SessionSnapshot(
        config: _plan?.config,
        frame: frame,
        status: status,
        error: error,
      ),
    );
    final active = [
      SessionStatus.loading,
      SessionStatus.playing,
      SessionStatus.paused,
    ].contains(status);
    final playing = status == SessionStatus.playing;
    playbackState.add(
      PlaybackState(
        controls: active
            ? [
                playing ? MediaControl.pause : MediaControl.play,
                MediaControl.stop,
              ]
            : [],
        systemActions: const {},
        androidCompactActionIndices: active ? [0, 1] : [],
        processingState: !active
            ? AudioProcessingState.idle
            : status == SessionStatus.loading
            ? AudioProcessingState.loading
            : buffering
            ? AudioProcessingState.buffering
            : AudioProcessingState.ready,
        playing: playing,
        updatePosition: frame?.elapsed ?? Duration.zero,
        bufferedPosition: frame?.elapsed ?? Duration.zero,
        queueIndex: 0,
      ),
    );
  }

  Future<void> _fail(int request, Object error) async {
    if (request != _request || _disposed) return;
    _acceptSnapshots = false;
    _wantPlayback = false;
    if (_previewMode != null) {
      _previewMode = null;
      _previews.add(PreviewSnapshot(error: error.toString()));
      playbackState.add(
        PlaybackState(processingState: AudioProcessingState.idle),
      );
    } else {
      _publish(SessionStatus.error, current.frame, error: error.toString());
    }
    try {
      await _port.stop();
    } catch (_) {
      /* Preserve the original decoding error. */
    }
  }

  Future<void> dispose() async {
    await stop();
    await _commands;
    _disposed = true;
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _port.dispose();
    await _states.close();
    await _previews.close();
  }
}
