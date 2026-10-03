import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicksleep/app.dart';
import 'package:quicksleep/audio/session_audio_handler.dart';
import 'package:quicksleep/settings/preferences.dart';
import 'package:quicksleep/session/session_plan.dart';
import 'support/fake_audio_port.dart';

void main() {
  for (final theme in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets(
      'capture ${theme.name} approved screens',
      (t) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        t.view.padding = const FakeViewPadding(top: 47, bottom: 34);
        addTearDown(() {
          t.view.resetPhysicalSize();
          t.view.resetDevicePixelRatio();
          t.view.resetPadding();
        });
        for (final family in ['NotoSansSC', 'NotoSerifSC']) {
          await (FontLoader(
            family,
          )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
        }
        SharedPreferences.setMockInitialValues({});
        final store = PreferencesStore(await SharedPreferences.getInstance());
        await store.save(
          AppPreferences(languageOverride: AppLanguage.zh, themeMode: theme),
        );
        final port = FakeAudioPort();
        final audio = SessionAudioHandler(port, fakeCatalog());
        final key = GlobalKey();
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: QuickSleepApp(audio: audio, preferences: store),
          ),
        );
        await t.pumpAndSettle();
        Future<void> capture(String name) async {
          await t.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            Directory('docs/screenshots').createSync(recursive: true);
            File(
              'docs/screenshots/${theme.name}_$name.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
        await t.runAsync(() async {
          for (final name in [
            'orb_night',
            'orb_light',
            'lock_night',
            'lock_light',
            'selected_night',
            'selected_light',
            'unselected_night',
            'unselected_light',
          ]) {
            await precacheImage(
              AssetImage('assets/visual/$name.png'),
              key.currentContext!,
            );
          }
        });
        await t.pumpAndSettle();
        await capture('home');
        await t.tap(find.byKey(const ValueKey('sound_mode')));
        await t.pumpAndSettle();
        await capture('sounds');
        await t.tap(find.byKey(const ValueKey('close_sound')));
        await t.pumpAndSettle();
        await t.ensureVisible(find.byKey(const ValueKey('start')));
        await t.tap(find.byKey(const ValueKey('start')));
        await t.pumpAndSettle();
        port.emit(position: const Duration(seconds: 2));
        await t.pump();
        await capture('session');
        expect(t.takeException(), isNull);
        await t.runAsync(audio.stop);
        await t.pumpWidget(const SizedBox.shrink());
        await t.runAsync(audio.dispose);
      },
      skip: Platform.environment['CAPTURE_SCREENSHOTS'] != '1',
    );
  }
}
