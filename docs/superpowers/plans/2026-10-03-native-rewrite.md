# QuickSleep Native Rewrite Implementation Plan

> **For agentic workers:** Implement task-by-task in this session. User authorization and repository workflow boundaries take precedence over generic skill handoff gates.

**Goal:** Deliver separate Kotlin Android and Swift iOS apps preserving the legacy product.

**Architecture:** Shared offline assets and product specification, independent native clients. Preassemble a finite WAV on a worker; native playback drives all progress and termination.

**Tech Stack:** Kotlin/Compose/Media3; Swift/SwiftUI/AVFoundation/MediaPlayer; Python standard library for resource preparation.

**Spec:** `docs/product/native-rewrite.md`

## Global Constraints

- Keep legacy untouched. Package ID com.qiyanzhixing.quicksleep.
- 2–60 whole minutes, default 10; 4 fixed breathing rounds; 15-second baked fade.
- Offline packaged resources; no runtime network permissions, TTS, playback history or auto-resume.
- Verify native business logic; no presentation-detail unit tests.

## Review Focus

- Stop or replacement while assembling must invalidate stale completion.
- Focus restoration and interruption end must never restart sound.
- Invalid saved values/custom text must fall back or be rejected.
- One active player; previews cannot replace a session or outlive their sheet.
- Disk/decoder failure must surface and allow a fresh attempt; completion must clear playback state.

### Task 1: Offline resources and contract tests
Files: scripts/prepare_assets.py, scripts/restore_assets.py, scripts/tests/test_assets.py, shared/assets, shared/asset_bundle, shared/session-vectors.json.
Produces: validated native audio/font/visual resources and generated native localization resources; representative shared session vectors.
- [x] Write tests for exact restoration, native destination files, catalog validation and audio splices; run RED.
- [x] Implement resource preparation, preserving license/provenance; run GREEN.

### Task 2: Android native application
Files: apps/android build configuration; app/src/main/kotlin/com/qiyanzhixing/quicksleep/{core,audio,ui}; app/src/test.
Interfaces: SessionPlan(config).segments/frameAt(seconds); WaveAssembler.write(plan, output, readAsset, cancelled); PlaybackService custom start/preview/end commands via MediaController.
- [x] Add plan tests for all 59 durations, boundaries, clamped progress, custom-input validation and WAV sample ordering. Initial native RED not run while SDK was unavailable; six tests subsequently passed on the installed toolchain.
- [x] Implement pure Kotlin plan and PCM assembly, then background service, settings and Compose screens.
- [x] Run unit tests, lint and debug APK build; record unavailable checks explicitly.

### Task 3: iOS native application
Files: apps/ios/QuickSleep/{Core,Audio,UI}, Package.swift, Tests, QuickSleep.xcodeproj.
Interfaces: SessionPlan(config:).segments/frame(at:); WaveAssembler.write; @MainActor PlaybackController owns AVPlayer and publishes state.
- [x] Add Swift core tests mirroring shared vectors and WAV checks.
- [x] Implement core, background audio/remote commands, settings, SwiftUI screens and native project.
- [ ] Run swift test and simulator build on macOS; record current Windows limitation.

### Task 4: Verification and handoff
Files: README.md, AGENTS.md, docs/architecture/native.md, docs/verification.md, .github/workflows/native.yml.
- [x] Add separate Android and macOS iOS CI jobs, resource verification and artifact uploads.
- [x] Review races, native API usage, packaging and privacy; adjust important findings, with iOS runtime verification still pending.
- [x] Run available checks and report exact evidence plus remaining device acceptance.

## Execution record

- Shared asset restoration is independent of legacy; the source bundle and provenance were copied without changing legacy.
- Android portable JDK 17, Gradle 8.13 and API 35 SDK installed in ignored .tools. Six core tests, lint (0 errors), APK build and packaged byte checks passed.
- iOS source/resource static checks and independent read-only review completed; actual Swift/Xcode execution remains pending on macOS.
- API 35 emulator confirmed installation/startup, language/theme changes and preview-sheet cleanup. The full two-minute background smoke run did not finish and remains pending.
