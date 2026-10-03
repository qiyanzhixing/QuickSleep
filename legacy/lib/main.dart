import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'audio/audio_catalog.dart';
import 'audio/just_audio_port.dart';
import 'audio/session_audio_handler.dart';
import 'l10n/generated/app_localizations.dart';
import 'settings/preferences.dart';
import 'theme/app_theme.dart';
import 'startup_coordinator.dart';

const audioServiceConfig = AudioServiceConfig(
  androidNotificationChannelId: 'com.qiyanzhixing.quicksleep.playback',
  androidNotificationChannelName: 'QuickSleep',
  androidStopForegroundOnPause: false,
  androidResumeOnClick: false,
);
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Bootstrap());
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late final StartupCoordinator<
    ({AudioCatalog catalog, PreferencesStore preferences}),
    SessionAudioHandler
  >
  startup;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    startup = StartupCoordinator(
      prepare: () async => (
        catalog: await loadAudioCatalog(rootBundle),
        preferences: PreferencesStore(await SharedPreferences.getInstance()),
      ),
      createService: (prepared) => AudioService.init<SessionAudioHandler>(
        builder: () => SessionAudioHandler(JustAudioPort(), prepared.catalog),
        config: audioServiceConfig,
      ),
      connect: (handler) async =>
          handler.connectInterruptions(await AudioSession.instance),
    );
    initialize();
  }

  Future<void> initialize() async {
    setState(() => failed = false);
    try {
      await startup.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (startup.ready) {
      return QuickSleepApp(
        audio: startup.service!,
        preferences: startup.preparation!.preferences,
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: sleepTheme(Brightness.light),
      darkTheme: sleepTheme(Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, _) =>
          Locale(locale?.languageCode == 'zh' ? 'zh' : 'en'),
      home: Builder(
        builder: (context) {
          final l = AppLocalizations.of(context)!;
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: failed
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              startup.restartRequired
                                  ? l.restartRequired
                                  : l.startupError,
                              key: startup.restartRequired
                                  ? const ValueKey('startup_restart_required')
                                  : null,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            if (!startup.restartRequired)
                              FilledButton(
                                onPressed: initialize,
                                child: Text(l.retry),
                              ),
                          ],
                        )
                      : const CircularProgressIndicator(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
