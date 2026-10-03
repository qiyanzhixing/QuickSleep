import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicksleep/app.dart';
import 'package:quicksleep/audio/session_audio_handler.dart';
import 'package:quicksleep/settings/preferences.dart';
import 'package:quicksleep/session/session_plan.dart';
import 'package:quicksleep/ui/session_screen.dart';
import 'package:quicksleep/ui/settings_screen.dart';
import 'support/fake_audio_port.dart';

void main() {
  late FakeAudioPort port;
  late SessionAudioHandler audio;
  late PreferencesStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    port = FakeAudioPort();
  });
  Future<void> open(WidgetTester tester, {AppPreferences? initial}) async {
    store = PreferencesStore(await SharedPreferences.getInstance());
    if (initial != null) await store.save(initial);
    audio = SessionAudioHandler(port, fakeCatalog());
    await tester.pumpWidget(QuickSleepApp(audio: audio, preferences: store));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, String key) async {
    await t.ensureVisible(find.byKey(ValueKey(key)));
    await t.tap(find.byKey(ValueKey(key)));
    await t.pumpAndSettle();
  }

  testWidgets('default configuration and double start create one session', (
    t,
  ) async {
    await open(t);
    await t.ensureVisible(find.byKey(const ValueKey('start')));
    final startAction = t
        .widget<FilledButton>(find.byKey(const ValueKey('start')))
        .onPressed!;
    startAction();
    startAction();
    await t.pumpAndSettle();
    expect(find.byType(SessionScreen), findsOneWidget);
    expect(port.playCalls, 1);
    expect(audio.current.config!.minutes, 10);
    expect(audio.current.config!.mode, SoundMode.moon);
    await tap(t, 'pause_resume');
    expect(audio.current.status, SessionStatus.paused);
    await tap(t, 'pause_resume');
    expect(port.playCalls, 2);
    await tap(t, 'end');
    expect(audio.current.status, SessionStatus.idle);
    expect(find.byType(SessionScreen), findsNothing);
  });
  testWidgets(
    'custom duration validates both limits and rejects invalid values',
    (t) async {
      await open(t);
      await tap(t, 'duration_custom');
      await t.enterText(find.byKey(const ValueKey('duration_input')), '61');
      await tap(t, 'save_duration');
      expect(find.byKey(const ValueKey('duration_input')), findsOneWidget);
      expect((await store.load()).minutes, 10);
      await t.enterText(find.byKey(const ValueKey('duration_input')), '2');
      await tap(t, 'save_duration');
      expect((await store.load()).minutes, 2);
      await tap(t, 'duration_custom');
      await t.enterText(find.byKey(const ValueKey('duration_input')), '60');
      await tap(t, 'save_duration');
      expect((await store.load()).minutes, 60);
    },
  );
  testWidgets('sound selection persists and closing the sheet stops preview', (
    t,
  ) async {
    await open(t);
    await tap(t, 'sound_mode');
    await tap(t, 'mode_forest');
    expect((await store.load()).mode, SoundMode.forest);
    await tap(t, 'preview_forest');
    expect(port.playCalls, 1);
    await tap(t, 'close_sound');
    expect(port.stopCalls, greaterThanOrEqualTo(2));
    expect(audio.previewStates.value.mode, isNull);
  });
  testWidgets('delayed End completion cannot pop a newer Settings route', (
    t,
  ) async {
    await open(t);
    await tap(t, 'start');
    final gate = Completer<void>();
    port.nextStop = gate;
    await t.ensureVisible(find.byKey(const ValueKey('end')));
    await t.tap(find.byKey(const ValueKey('end')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('session_settings')));
    await t.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    gate.complete();
    await t.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(SessionScreen, skipOffstage: false), findsNothing);
  });
  testWidgets('the visible settings control has a full-height tap target', (
    t,
  ) async {
    await open(t);
    final rect = t.getRect(find.byKey(const ValueKey('settings')));
    await t.tapAt(Offset(rect.center.dx, rect.top + 3));
    await t.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
  testWidgets('external stop returns the visible session to home', (t) async {
    await open(t);
    await tap(t, 'start');
    await t.runAsync(audio.stop);
    await t.pumpAndSettle();
    expect(find.byType(SessionScreen, skipOffstage: false), findsNothing);
    expect(find.byKey(const ValueKey('start')), findsOneWidget);
  });
  testWidgets(
    'external stop removes only its session underneath newer settings',
    (t) async {
      await open(t);
      await tap(t, 'start');
      await tap(t, 'session_settings');
      expect(find.byType(SessionScreen, skipOffstage: false), findsOneWidget);
      await t.runAsync(audio.stop);
      await t.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(SessionScreen, skipOffstage: false), findsNothing);
      await t.pageBack();
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('start')), findsOneWidget);
    },
  );
  testWidgets('large-text brand and settings retain their full height', (
    t,
  ) async {
    t.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await open(t);
    expect(t.getSize(find.text('QuickSleep')).height, greaterThan(48));
    expect(
      t.getSize(find.byKey(const ValueKey('settings'))).height,
      greaterThanOrEqualTo(44),
    );
  });
  testWidgets(
    'language/theme apply now and active audio config remains frozen',
    (t) async {
      await open(
        t,
        initial: const AppPreferences(languageOverride: AppLanguage.zh),
      );
      await tap(t, 'start');
      expect(audio.current.config!.language, AppLanguage.zh);
      await tap(t, 'session_settings');
      await tap(t, 'language_en');
      await tap(t, 'theme_light');
      expect((await store.load()).languageOverride, AppLanguage.en);
      expect((await store.load()).themeMode, ThemeMode.light);
      expect(audio.current.config!.language, AppLanguage.zh);
      expect(find.text('Appearance'), findsOneWidget);
    },
  );
}
