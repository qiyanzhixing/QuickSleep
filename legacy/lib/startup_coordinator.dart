/// Keeps a single-use native service separate from retryable preparation and
/// audio-session configuration. A failed native init requires a process restart.
class StartupCoordinator<P extends Object, S extends Object> {
  StartupCoordinator({
    required this.prepare,
    required this.createService,
    required this.connect,
  });
  final Future<P> Function() prepare;
  final Future<S> Function(P) createService;
  final Future<void> Function(S) connect;
  P? preparation;
  S? service;
  bool ready = false;
  bool restartRequired = false;
  bool _serviceAttempted = false;
  Future<void>? _inFlight;

  Future<void> initialize() {
    if (ready) return Future.value();
    if (_inFlight != null) return _inFlight!;
    final work = _initialize();
    _inFlight = work;
    return work.whenComplete(() => _inFlight = null);
  }

  Future<void> _initialize() async {
    if (restartRequired) {
      throw StateError('Native service requires a process restart');
    }
    preparation ??= await prepare();
    if (service == null) {
      if (_serviceAttempted) {
        throw StateError('Native service was already initialized');
      }
      _serviceAttempted = true;
      try {
        service = await createService(preparation!);
      } catch (_) {
        restartRequired = true;
        rethrow;
      }
    }
    await connect(service!);
    ready = true;
  }
}
