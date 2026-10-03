import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service_platform_interface/audio_service_platform_interface.dart';
import 'package:quicksleep/main.dart' as app;

class FailingService extends AudioServicePlatform {
  int calls = 0;
  @override
  void setHandlerCallbacks(AudioHandlerCallbacks c) {}
  @override
  Future<void> configure(ConfigureRequest r) async {
    calls++;
    if (calls == 1) throw PlatformException(code: 'temporary_native_error');
  }

  @override
  Future<void> setState(SetStateRequest r) async {}
  @override
  Future<void> setQueue(SetQueueRequest r) async {}
  @override
  Future<void> setMediaItem(SetMediaItemRequest r) async {}
  @override
  Future<void> setAndroidPlaybackInfo(SetAndroidPlaybackInfoRequest r) async {}
}

void main() {
  testWidgets(
    'single-use native initialization failure honestly requires restart',
    (t) async {
      SharedPreferences.setMockInitialValues({});
      final service = FailingService();
      AudioServicePlatform.instance = service;
      app.main();
      await t.pumpAndSettle();
      expect(find.text('Retry'), findsNothing);
      expect(
        find.byKey(const ValueKey('startup_restart_required')),
        findsOneWidget,
      );
      expect(service.calls, 1);
    },
  );
}
