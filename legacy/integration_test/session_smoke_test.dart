import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quicksleep/audio/audio_catalog.dart';
import 'package:quicksleep/audio/just_audio_port.dart';
import 'package:quicksleep/audio/session_audio_handler.dart';
import 'package:quicksleep/main.dart' show audioServiceConfig;
import 'package:quicksleep/session/session_plan.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native two-minute queue pauses, fades and ends without replay',
    (tester) async {
      final catalog = await loadAudioCatalog(rootBundle);
      final audio = await AudioService.init<SessionAudioHandler>(
        builder: () => SessionAudioHandler(JustAudioPort(), catalog),
        config: audioServiceConfig,
      );
      await audio.connectInterruptions(await AudioSession.instance);
      await tester.runAsync(() async {
        await audio.start(
          const SessionConfig(
            minutes: 2,
            mode: SoundMode.moon,
            language: AppLanguage.en,
          ),
        );
        await Future<void>.delayed(const Duration(seconds: 3));
        await audio.pause();
        final paused = audio.current.frame!.elapsed;
        await Future<void>.delayed(const Duration(seconds: 2));
        expect(
          (audio.current.frame!.elapsed - paused).inMilliseconds.abs(),
          lessThan(150),
        );
        expect(audio.current.status, SessionStatus.paused);
        await audio.play();
        await audio.sessionStates
            .firstWhere((s) => s.status == SessionStatus.completed)
            .timeout(const Duration(minutes: 3));
        expect(audio.current.frame!.remaining, Duration.zero);
        await Future<void>.delayed(const Duration(seconds: 2));
        expect(audio.current.status, SessionStatus.completed);
        expect(audio.playbackState.value.playing, false);
        await audio.dispose();
      });
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
