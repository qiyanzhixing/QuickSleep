# QuickSleep

A small, fully offline Flutter app for Android and iOS. 简体中文 / English.

- Choose 5, 10, 15 or a custom **2–60 whole minutes** (default 10)
- Three pre-mixed sound modes: Moonlit Whispers, Mountain Stillness, Forest Evening Breeze
- Four fixed rounds of 4–7–8 breathing, then natural breathing with background sound
- Total time includes the guidance and the last **15-second baked-in fade**
- Finite native playlist, lock-screen controls, pause/resume and interruption handling
- System/manual language and Night/Light appearance; preferences stay on-device
- No account, ads, analytics, remote fonts, streaming or runtime TTS

All narration is synthesized. Mountain Stillness uses **guqin-inspired synthesized plucks (仿古琴合成音)**, not a recording of a guqin performance. This is a relaxation tool, not medical treatment. Stop and breathe naturally if the exercise feels uncomfortable.

## Run

Use **Flutter 3.35.7 / Dart 3.9.2**, pinned in `.fvmrc`, and the committed `pubspec.lock`.

```sh
python3 tools/restore_assets.py
flutter pub get
flutter gen-l10n
flutter run
```

Android needs a JDK and Android SDK (compile/target API 36, NDK 27.0.12077973). Accept Google's SDK agreement during installation. The app's package ID is `com.qiyanzhixing.quicksleep`.

```sh
flutter build apk --debug
# output: build/app/outputs/flutter-apk/app-debug.apk
```

On macOS, install Xcode and CocoaPods, then:

```sh
flutter build ios --simulator --debug
# Or open ios/Runner.xcworkspace for a physical device and select your own team.
```

Simulator builds do not provide a signed iPhone installation package. No store upload, distribution certificate or signing credential is configured here. Debug Android builds use the normal local development signing key; configure your own release signing before distributing.

## Checks

```sh
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
python3 -m pip install numpy
python3 -m unittest discover -s tools/audio/tests -v
python3 tools/audio/verify_assets.py assets/audio
```

The workflow checks the same commit on Linux and macOS, and uploads a debug APK and an iOS simulator app when those builds pass. Check the actual run, not just the presence of the workflow.

With an Android or iOS device connected, run the native two-minute smoke test:

```sh
flutter devices
flutter test integration_test/session_smoke_test.dart -d DEVICE_ID
```

Real phone checks remain essential: airplane-mode first launch, ten-minute lock-screen playback, phone calls, wired/Bluetooth disconnection, manual resume, fade, and force-stop behavior. See [the verification report](docs/verification.md) for what has and has not actually been verified.

## Audio and design

The repository includes the exact bytes of 18 ready-to-play PCM WAVs and three Noto fonts in a lossless, SHA-verified source bundle, plus original Figma artwork. `python3 tools/restore_assets.py` (or `make setup`) restores these files from small local parts before Flutter runs. This uses only Python’s standard library, has no network access, and never downloads a voice model. CI performs the same required restore automatically. The complete session is scheduled before playback; UI timers never trigger audio transitions or the end.

[Audio sources, licenses and regeneration](docs/audio-sources.md) · [Architecture](docs/architecture.md) · [Design screenshots](docs/screenshots)

```sh
python3 -m venv .audio-venv
. .audio-venv/bin/activate
pip install torch==2.8.0 --index-url https://download.pytorch.org/whl/cpu
pip install -r tools/audio/requirements.txt
python tools/audio/generate_assets.py --output assets/audio
python tools/audio/verify_assets.py assets/audio
python tools/package_assets.py
```

After changing audio or fonts, regenerate the lossless bundle with `python3 tools/package_assets.py` and commit its updated parts/manifest. Ordinary app builds only restore finished bytes. Optional voice generation downloads pinned open-source models; the mobile app never downloads or bundles those models. Listen to every regenerated voice before relying on it. Automated speech recognition can mishear short, repetitive counting and is not human listening approval.
