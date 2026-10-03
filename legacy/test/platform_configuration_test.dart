import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'iOS configurations include CocoaPods dependencies and background audio',
    () {
      expect(
        File('ios/Flutter/Debug.xcconfig').readAsStringSync(),
        contains('Pods-Runner.debug.xcconfig'),
      );
      expect(
        File('ios/Flutter/Release.xcconfig').readAsStringSync(),
        contains('Pods-Runner.release.xcconfig'),
      );
      final info = File('ios/Runner/Info.plist').readAsStringSync();
      expect(info, contains('<string>audio</string>'));
      expect(info, contains('UIBackgroundModes'));
      expect(info, isNot(contains('NSMicrophoneUsageDescription')));
    },
  );
  test('release builds are never signed using the disposable debug key', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
  });
  test(
    'Android release manifest only requests local media playback permissions',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, contains('FOREGROUND_SERVICE_MEDIA_PLAYBACK'));
      expect(manifest, contains('AudioService'));
      expect(manifest, isNot(contains('android.permission.INTERNET')));
      expect(manifest, isNot(contains('RECORD_AUDIO')));
    },
  );
}
