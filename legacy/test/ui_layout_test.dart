import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicksleep/app.dart';
import 'package:quicksleep/audio/session_audio_handler.dart';
import 'package:quicksleep/settings/preferences.dart';
import 'package:quicksleep/session/session_plan.dart';
import 'support/fake_audio_port.dart';

void main() {
  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    for (final language in AppLanguage.values) {
      for (final theme in [ThemeMode.dark, ThemeMode.light]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets(
            '${size.width} $language $theme scale $scale never overflows and actions remain reachable',
            (t) async {
              t.view.physicalSize = size;
              t.view.devicePixelRatio = 1;
              t.platformDispatcher.textScaleFactorTestValue = scale;
              addTearDown(() {
                t.view.resetPhysicalSize();
                t.view.resetDevicePixelRatio();
                t.platformDispatcher.clearTextScaleFactorTestValue();
              });
              SharedPreferences.setMockInitialValues({});
              final store = PreferencesStore(
                await SharedPreferences.getInstance(),
              );
              await store.save(
                AppPreferences(themeMode: theme, languageOverride: language),
              );
              final audio = SessionAudioHandler(FakeAudioPort(), fakeCatalog());

              await t.pumpWidget(
                QuickSleepApp(audio: audio, preferences: store),
              );
              await t.pumpAndSettle();
              expect(t.takeException(), isNull);
              expect(find.text('9:41'), findsNothing);
              await t.ensureVisible(find.byKey(const ValueKey('start')));
              expect(t.takeException(), isNull);
              await t.ensureVisible(find.byKey(const ValueKey('sound_mode')));
              await t.tap(find.byKey(const ValueKey('sound_mode')));
              await t.pumpAndSettle();
              expect(t.takeException(), isNull);
              await t.ensureVisible(
                find.byKey(const ValueKey('preview_forest')),
              );
              expect(t.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
