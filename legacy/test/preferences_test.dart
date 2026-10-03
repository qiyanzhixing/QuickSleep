import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicksleep/settings/preferences.dart';
import 'package:quicksleep/session/session_plan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('custom duration accepts only whole minutes within 2–60', () {
    for (final s in ['', '1', '61', '2.5', 'abc', '-2', '2e1']) {
      expect(parseCustomMinutes(s), isNull);
    }
    expect(parseCustomMinutes('2'), 2);
    expect(parseCustomMinutes('60'), 60);
    expect(parseCustomMinutes(' 10 '), 10);
  });
  test('language resolves Chinese or English with manual override', () {
    expect(resolveLanguage('zh', null), AppLanguage.zh);
    expect(resolveLanguage('fr', null), AppLanguage.en);
    expect(resolveLanguage('zh', AppLanguage.en), AppLanguage.en);
  });
  test('missing and corrupted settings restore safe defaults', () async {
    SharedPreferences.setMockInitialValues({'preferences': 'broken'});
    final store = PreferencesStore(await SharedPreferences.getInstance());
    final p = await store.load();
    expect(p.minutes, 10);
    expect(p.mode, SoundMode.moon);
    expect(p.themeMode, ThemeMode.system);
    expect(p.languageOverride, isNull);
    SharedPreferences.setMockInitialValues({
      'preferences': '{"minutes":-1,"mode":"bad","theme":"bad","language":17}',
    });
    expect(
      (await PreferencesStore(
        await SharedPreferences.getInstance(),
      ).load()).minutes,
      10,
    );
  });
  test('preferences survive save/load', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PreferencesStore(await SharedPreferences.getInstance());
    await store.save(
      const AppPreferences(
        minutes: 60,
        mode: SoundMode.forest,
        themeMode: ThemeMode.light,
        languageOverride: AppLanguage.en,
      ),
    );
    final p = await store.load();
    expect(p.minutes, 60);
    expect(p.mode, SoundMode.forest);
    expect(p.themeMode, ThemeMode.light);
    expect(p.languageOverride, AppLanguage.en);
  });
}
