# Verification

Local verification: **2026-10-01**, Flutter **3.35.7**, Dart **3.9.2**. The pull request identifies the published commit and its exact GitHub Actions results.

## Passed locally on the final application code

- `dart format --output=none --set-exit-if-changed lib test integration_test`: clean
- `flutter analyze --no-pub`: no issues
- `flutter test --no-pub`: **55 passed**, two opt-in screenshot captures skipped in the default suite
- `CAPTURE_SCREENSHOTS=1 flutter test --no-pub test/screenshots_test.dart`: **2 passed**; rendered pixels visually inspected against the approved Figma home/sound designs
- Layout matrix: Chinese/English × Night/Light × 320×568/390×844 × text scale 1.0/2.0; separate tests cover silently clipped text and edge-of-control taps
- Python asset tests: **6 passed**, covering audio validity, exact clean-directory restoration, corrupted parts rejected before writes, missing files rejected by check mode, and hostile pre-existing temporary symlinks cannot escape the output directory
- Audio verification: **18 real WAVs passed** exact duration, SHA256, audible RMS, peak, fade-ending and splice-sample checks
- `flutter build apk --debug --no-pub`: **passed**, final rebuild completed in 87 seconds
- APK archive inspection: all **18 audio files and 3 fonts** match their catalog hashes
- Debug APK: **206,100,712 bytes**; SHA256 `a1523ce169dfce5b93e49dfa39aea92dab59e9ff1fef476a284a0d42a68b1261`

The universal debug APK is large because it includes Flutter debugging support and multiple Android architectures. It is for personal testing, not production distribution. Release signing is deliberately unconfigured. No private signing key is committed.

## Independent review and fixes

The whole branch received an independent review before publication. Regression tests reproduced and fixed:

1. Lock-screen/external Stop leaving a stale session screen, and delayed End closing a newer Settings route. Completion now targets the exact session route
2. Retrying single-use `AudioService.init` after a native initialization failure. Startup now distinguishes retryable preparation/configuration from a failure requiring a process restart, and reuses an already-created handler
3. The fixed-height header clipping enlarged text and shrinking the Settings control's effective tap area

A separate decoder-error cleanup/replacement-load race was reproduced and fixed before review. The native Dart adapter's segment-boundary index/position pairing was independently checked with simulated platform events. These checks do not substitute for a physical device.

## Lossless checkout restoration

The final source bundle restores the exact 18 WAVs and three font files used by the verified APK. A separate clean-directory restore and per-file SHA256 comparison passed. No runtime code or audio was changed by this repository packaging step. Fresh checkouts must run `python3 tools/restore_assets.py` (or `make setup`); CI does this automatically.

## GitHub checks

The workflow checks the same published revision in three jobs: analysis/tests, Android debug APK, and macOS iOS simulator build. **Read the target commit's Checks/Actions result for pass/fail status.** This file does not assume a configured workflow has run successfully.

## Not verified here

- Android/iOS native integration-test execution: `flutter devices` found only Linux desktop, no Android/iOS device
- Ten-minute physical-device lock-screen playback and final fade on each platform
- Actual calls, wired/Bluetooth disconnection, manual resume and force-stop behavior
- Human listening approval of all six guide/preview pairs. Machine recognition is diagnostic and sometimes mishears short counting
- Local iOS compilation: this Linux environment has no Xcode; iOS compilation is assigned to the macOS CI job
- iPhone signing/installation or store submission

Do not interpret mocked-port tests as OS background-playback validation, or simulator compilation as a signed iPhone deliverable. Real-device and listening acceptance remain pending.
