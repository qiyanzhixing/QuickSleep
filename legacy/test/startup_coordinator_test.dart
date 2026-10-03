import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicksleep/startup_coordinator.dart';

void main() {
  test(
    'pre-service preparation can retry without initializing the service twice',
    () async {
      var prepares = 0, creates = 0;
      final startup = StartupCoordinator<int, Object>(
        prepare: () async {
          if (++prepares == 1) throw StateError('temporary asset error');
          return 7;
        },
        createService: (p) async {
          creates++;
          expect(p, 7);
          return Object();
        },
        connect: (_) async {},
      );
      await expectLater(startup.initialize(), throwsStateError);
      expect(startup.restartRequired, false);
      await startup.initialize();
      expect(startup.ready, true);
      expect(creates, 1);
    },
  );
  test(
    'failed service creation is never retried in the same process',
    () async {
      var calls = 0;
      final startup = StartupCoordinator<int, Object>(
        prepare: () async => 7,
        createService: (_) async {
          calls++;
          throw StateError('native init failed');
        },
        connect: (_) async {},
      );
      await expectLater(startup.initialize(), throwsStateError);
      expect(startup.restartRequired, true);
      await expectLater(startup.initialize(), throwsStateError);
      expect(calls, 1);
    },
  );
  test(
    'interruption configuration retry reuses the original handler',
    () async {
      var creates = 0, connects = 0;
      final service = Object();
      final startup = StartupCoordinator<int, Object>(
        prepare: () async => 1,
        createService: (_) async {
          creates++;
          return service;
        },
        connect: (s) async {
          expect(identical(s, service), true);
          if (++connects == 1) throw StateError('temporary session error');
        },
      );
      await expectLater(startup.initialize(), throwsStateError);
      expect(startup.restartRequired, false);
      await startup.initialize();
      expect(startup.ready, true);
      expect(creates, 1);
      expect(connects, 2);
    },
  );
  test('concurrent startup requests are coalesced', () async {
    var creates = 0;
    final gate = Completer<int>();
    final startup = StartupCoordinator<int, Object>(
      prepare: () => gate.future,
      createService: (_) async {
        creates++;
        return Object();
      },
      connect: (_) async {},
    );
    final a = startup.initialize(), b = startup.initialize();
    gate.complete(1);
    await Future.wait([a, b]);
    expect(creates, 1);
  });
}
