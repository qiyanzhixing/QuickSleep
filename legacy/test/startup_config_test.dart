import 'package:flutter_test/flutter_test.dart';
import 'package:quicksleep/main.dart';

void main() {
  test(
    'background service configuration is valid and never resumes from a notification tap',
    () {
      expect(audioServiceConfig.androidStopForegroundOnPause, false);
      expect(audioServiceConfig.androidResumeOnClick, false);
    },
  );
}
