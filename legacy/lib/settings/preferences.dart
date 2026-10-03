import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../session/session_plan.dart';

int? parseCustomMinutes(String input) {
  final value = input.trim();
  if (!RegExp(r'^\d+$').hasMatch(value)) return null;
  final n = int.tryParse(value);
  return n != null && n >= 2 && n <= 60 ? n : null;
}

AppLanguage resolveLanguage(String systemLanguageCode, AppLanguage? override) =>
    override ??
    (systemLanguageCode.toLowerCase() == 'zh'
        ? AppLanguage.zh
        : AppLanguage.en);

class AppPreferences {
  const AppPreferences({
    this.minutes = 10,
    this.mode = SoundMode.moon,
    this.themeMode = ThemeMode.system,
    this.languageOverride,
  });
  final int minutes;
  final SoundMode mode;
  final ThemeMode themeMode;
  final AppLanguage? languageOverride;
  AppPreferences copyWith({
    int? minutes,
    SoundMode? mode,
    ThemeMode? themeMode,
    AppLanguage? languageOverride,
    bool useSystemLanguage = false,
  }) => AppPreferences(
    minutes: minutes ?? this.minutes,
    mode: mode ?? this.mode,
    themeMode: themeMode ?? this.themeMode,
    languageOverride: useSystemLanguage
        ? null
        : languageOverride ?? this.languageOverride,
  );
}

class PreferencesStore {
  PreferencesStore(this._storage);
  final SharedPreferences _storage;
  Future<void> _pending = Future.value();
  Future<AppPreferences> load() async {
    try {
      final raw = _storage.getString('preferences');
      if (raw == null) return const AppPreferences();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      T enumOr<T extends Enum>(List<T> values, Object? name, T fallback) =>
          values.where((v) => v.name == name).firstOrNull ?? fallback;
      final value = data['minutes'];
      return AppPreferences(
        minutes: value is int && value >= 2 && value <= 60 ? value : 10,
        mode: enumOr(SoundMode.values, data['mode'], SoundMode.moon),
        themeMode: enumOr(ThemeMode.values, data['theme'], ThemeMode.system),
        languageOverride: AppLanguage.values
            .where((v) => v.name == data['language'])
            .firstOrNull,
      );
    } catch (_) {
      return const AppPreferences();
    }
  }

  Future<void> save(AppPreferences value) {
    final encoded = jsonEncode({
      'minutes': value.minutes,
      'mode': value.mode.name,
      'theme': value.themeMode.name,
      'language': value.languageOverride?.name,
    });
    final result = _pending.catchError((Object _) {}).then((_) async {
      if (!await _storage.setString('preferences', encoded)) {
        throw StateError('Could not save preferences');
      }
    });
    _pending = result;
    return result;
  }
}
