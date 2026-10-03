import 'dart:async';
import 'package:flutter/material.dart';
import '../audio/session_audio_handler.dart';
import '../l10n/generated/app_localizations.dart';
import '../session/session_plan.dart';
import '../theme/app_theme.dart';
import 'breathing_orb.dart';
import 'sound_mode_sheet.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({
    super.key,
    required this.audio,
    required this.onSettings,
  });
  final SessionAudioHandler audio;
  final VoidCallback onSettings;
  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  bool closing = false;
  Route<dynamic>? sessionRoute;
  StreamSubscription<SessionSnapshot>? subscription;
  @override
  void initState() {
    super.initState();
    subscription = widget.audio.sessionStates.listen((state) {
      if (state.status == SessionStatus.idle && !closing) {
        closing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => closeOwnRoute());
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sessionRoute ??= ModalRoute.of(context);
  }

  void closeOwnRoute() {
    if (!mounted) return;
    final route = sessionRoute;
    final navigator = route?.navigator;
    if (route == null || navigator == null || !route.isActive) return;
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  Future<void> end() async {
    if (closing) return;
    closing = true;
    await widget.audio.stop();
    closeOwnRoute();
  }

  @override
  void dispose() {
    unawaited(subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<SessionSnapshot>(
    stream: widget.audio.sessionStates,
    initialData: widget.audio.current,
    builder: (context, snapshot) {
      final state = snapshot.data!;
      final config = state.config;
      final l = config == null
          ? AppLocalizations.of(context)!
          : lookupAppLocalizations(Locale(config.language.name));
      final frame = state.frame;
      final finished = state.status == SessionStatus.completed;
      final failed = state.status == SessionStatus.error;
      final seconds = frame?.remaining.inSeconds ?? 0;
      final time =
          '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
      final phase = switch (frame?.phase) {
        BreathPhase.inhale => l.inhale,
        BreathPhase.hold => l.hold,
        BreathPhase.exhale => l.exhale,
        BreathPhase.fade => l.fading,
        BreathPhase.complete => l.completed,
        _ => l.natural,
      };
      final label = state.status == SessionStatus.loading
          ? l.loading
          : state.status == SessionStatus.paused
          ? l.paused
          : failed
          ? l.audioError
          : phase;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) end();
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(l.appTitle),
            actions: [
              IconButton(
                key: const ValueKey('session_settings'),
                tooltip: l.settings,
                onPressed: widget.onSettings,
                icon: const Icon(Icons.tune, size: 20),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 28),
                      Text(
                        config == null
                            ? l.sessionTitle
                            : modeName(l, config.mode),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: BreathingOrb(
                          frame: frame,
                          reduceMotion: MediaQuery.disableAnimationsOf(context),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      if (frame?.count != null && !failed)
                        Text(
                          '${frame!.count}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontSize: 48,
                                color: context.colors.accent,
                              ),
                        ),
                      if (frame?.cycle != null && !failed)
                        Text(
                          l.round(frame!.cycle!),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 24),
                      Text(
                        l.remaining(time),
                        key: const ValueKey('remaining'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      if (!finished && !failed)
                        FilledButton(
                          key: const ValueKey('pause_resume'),
                          onPressed: state.status == SessionStatus.paused
                              ? widget.audio.play
                              : widget.audio.pause,
                          child: Text(
                            state.status == SessionStatus.paused
                                ? l.resume
                                : l.pause,
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextButton(
                        key: const ValueKey('end'),
                        onPressed: end,
                        child: Text(finished || failed ? l.backHome : l.end),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l.safetyHint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
