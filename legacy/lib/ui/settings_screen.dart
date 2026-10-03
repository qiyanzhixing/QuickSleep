import 'package:flutter/material.dart';
import '../settings/preferences.dart';
import '../session/session_plan.dart';
import '../l10n/generated/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.preferences,
    required this.onChanged,
  });
  final AppPreferences preferences;
  final ValueChanged<AppPreferences> onChanged;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppPreferences value = widget.preferences;
  void change(AppPreferences next) {
    setState(() => value = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    Widget option(String key, String label, bool selected, VoidCallback tap) =>
        ListTile(
          key: ValueKey(key),
          title: Text(label),
          trailing: selected ? const Icon(Icons.check) : null,
          onTap: tap,
        );
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(l.language, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            option(
              'language_system',
              l.system,
              value.languageOverride == null,
              () => change(value.copyWith(useSystemLanguage: true)),
            ),
            option(
              'language_zh',
              l.chinese,
              value.languageOverride == AppLanguage.zh,
              () => change(value.copyWith(languageOverride: AppLanguage.zh)),
            ),
            option(
              'language_en',
              l.english,
              value.languageOverride == AppLanguage.en,
              () => change(value.copyWith(languageOverride: AppLanguage.en)),
            ),
            const SizedBox(height: 24),
            Text(l.theme, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            option(
              'theme_system',
              l.system,
              value.themeMode == ThemeMode.system,
              () => change(value.copyWith(themeMode: ThemeMode.system)),
            ),
            option(
              'theme_dark',
              l.night,
              value.themeMode == ThemeMode.dark,
              () => change(value.copyWith(themeMode: ThemeMode.dark)),
            ),
            option(
              'theme_light',
              l.light,
              value.themeMode == ThemeMode.light,
              () => change(value.copyWith(themeMode: ThemeMode.light)),
            ),
            const SizedBox(height: 24),
            Text(l.nextSessionHint),
            const SizedBox(height: 16),
            Text(l.offlineNote),
            const SizedBox(height: 16),
            Text(l.syntheticNote, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            Text(l.safetyHint, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
