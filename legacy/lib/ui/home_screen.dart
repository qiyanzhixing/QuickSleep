import 'dart:async';
import 'package:flutter/material.dart';
import '../audio/session_audio_handler.dart';
import '../l10n/generated/app_localizations.dart';
import '../session/session_plan.dart';
import '../settings/preferences.dart';
import '../theme/app_theme.dart';
import 'breathing_orb.dart';
import 'duration_sheet.dart';
import 'session_screen.dart';
import 'settings_screen.dart';
import 'sound_mode_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.audio,
    required this.preferences,
    required this.onPreferencesChanged,
  });
  final SessionAudioHandler audio;
  final AppPreferences preferences;
  final ValueChanged<AppPreferences> onPreferencesChanged;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool sessionOpen = false;
  void settings() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SettingsScreen(
        preferences: widget.preferences,
        onChanged: widget.onPreferencesChanged,
      ),
    ),
  );
  Future<void> start() async {
    if (sessionOpen) return;
    setState(() => sessionOpen = true);
    final language = AppLanguage.values.byName(
      Localizations.localeOf(context).languageCode,
    );
    unawaited(
      widget.audio.start(
        SessionConfig(
          minutes: widget.preferences.minutes,
          mode: widget.preferences.mode,
          language: language,
        ),
      ),
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SessionScreen(audio: widget.audio, onSettings: settings),
      ),
    );
    if (mounted) setState(() => sessionOpen = false);
  }

  Widget durationOption(BuildContext context, int? minutes) {
    final c = context.colors;
    final l = AppLocalizations.of(context)!;
    final selected = minutes == null
        ? ![5, 10, 15].contains(widget.preferences.minutes)
        : minutes == widget.preferences.minutes;
    final label = minutes == null
        ? (![5, 10, 15].contains(widget.preferences.minutes)
              ? l.minutes(widget.preferences.minutes)
              : l.customDuration)
        : l.minutes(minutes);
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? c.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: ValueKey(
            minutes == null ? 'duration_custom' : 'duration_$minutes',
          ),
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            if (minutes != null) {
              widget.onPreferencesChanged(
                widget.preferences.copyWith(minutes: minutes),
              );
              return;
            }
            final value = await showDurationSheet(
              context,
              widget.preferences.minutes,
            );
            if (value != null && mounted) {
              widget.onPreferencesChanged(
                widget.preferences.copyWith(minutes: value),
              );
            }
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? c.ink : c.secondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 478),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Text(
                            l.appTitle,
                            style: text.titleMedium?.copyWith(
                              color: c.secondary,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: IconButton(
                              key: const ValueKey('settings'),
                              onPressed: settings,
                              tooltip: l.settings,
                              icon: const Icon(Icons.tune, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l.introTitle,
                      textAlign: TextAlign.center,
                      style: text.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.introSubtitle,
                      textAlign: TextAlign.center,
                      style: text.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    const Center(child: BreathingOrb()),
                    const SizedBox(height: 18),
                    Text(
                      l.durationTitle,
                      textAlign: TextAlign.center,
                      style: text.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border, width: .7),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final large =
                                MediaQuery.textScalerOf(context).scale(16) > 22;
                            final width =
                                (constraints.maxWidth - (large ? 4 : 12)) /
                                (large ? 2 : 4);
                            return Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                for (final minutes in [5, 10, 15, null])
                                  SizedBox(
                                    width: width,
                                    child: durationOption(context, minutes),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.durationHint,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: c.muted),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        key: const ValueKey('sound_mode'),
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => showSoundModeSheet(
                          context,
                          audio: widget.audio,
                          selected: widget.preferences.mode,
                          language: AppLanguage.values.byName(
                            Localizations.localeOf(context).languageCode,
                          ),
                          onChanged: (mode) => widget.onPreferencesChanged(
                            widget.preferences.copyWith(mode: mode),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(l.soundMode)),
                                  Text(
                                    l.change,
                                    style: TextStyle(color: c.accent),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: c.accent,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                modeName(l, widget.preferences.mode),
                                style: text.titleMedium,
                              ),
                              const SizedBox(height: 3),
                              Text(modeDescription(l, widget.preferences.mode)),
                              const SizedBox(height: 8),
                              Text(l.mixedHint, style: text.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 56),
                    FilledButton(
                      key: const ValueKey('start'),
                      onPressed: sessionOpen ? null : start,
                      child: Text(l.start, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/visual/lock_${context.assetTheme}.png',
                          width: 14,
                          height: 16,
                          excludeFromSemantics: true,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l.lockHint,
                            textAlign: TextAlign.center,
                            style: text.bodyMedium?.copyWith(color: c.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
