import 'package:flutter/material.dart';
import 'audio/session_audio_handler.dart';
import 'l10n/generated/app_localizations.dart';
import 'settings/preferences.dart';
import 'theme/app_theme.dart';
import 'ui/home_screen.dart';

class QuickSleepApp extends StatefulWidget {
  const QuickSleepApp({
    super.key,
    required this.audio,
    required this.preferences,
  });
  final SessionAudioHandler audio;
  final PreferencesStore preferences;
  @override
  State<QuickSleepApp> createState() => _QuickSleepAppState();
}

class _QuickSleepAppState extends State<QuickSleepApp> {
  AppPreferences? value;
  final messenger = GlobalKey<ScaffoldMessengerState>();
  @override
  void initState() {
    super.initState();
    widget.preferences.load().then((p) {
      if (mounted) setState(() => value = p);
    });
  }

  Future<void> change(AppPreferences next) async {
    setState(() => value = next);
    try {
      await widget.preferences.save(next);
    } catch (_) {
      if (mounted) {
        final context = messenger.currentContext;
        if (context != null && context.mounted) {
          messenger.currentState?.showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.saveError)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'QuickSleep',
    debugShowCheckedModeBanner: false,
    scaffoldMessengerKey: messenger,
    theme: sleepTheme(Brightness.light),
    darkTheme: sleepTheme(Brightness.dark),
    themeMode: value?.themeMode ?? ThemeMode.system,
    locale: value?.languageOverride == null
        ? null
        : Locale(value!.languageOverride!.name),
    localeResolutionCallback: (locale, supported) => Locale(
      resolveLanguage(
        locale?.languageCode ?? 'en',
        value?.languageOverride,
      ).name,
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: value == null
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : HomeScreen(
            audio: widget.audio,
            preferences: value!,
            onPreferencesChanged: change,
          ),
  );
}
