# Architecture

- `SessionPlan` is pure Dart. It validates 2–60 minutes and produces `guide80 + bed60×(M−2) + bed[0:25] + fade15`, exactly `M×60` seconds.
- `frameAt` and `globalPosition` derive UI state from native media position. Pause consumes no session time. Each session freezes its original language, mode and duration.
- `SessionAudioHandler` owns the only `AudioPort`. Commands are serialized; request IDs immediately invalidate superseded loads, stop requests and closed previews. A stale load cannot play. Previews cannot replace an active session.
- `JustAudioPort` supplies a finite, preloaded native playlist with repeat/shuffle off and decoding errors surfaced. End/fade need no foreground Dart timer. All background beds and fade tails are original synthesis; tail volume is already encoded in the samples.
- `audio_session` interruption-begin and becoming-noisy events pause. Interruption-end does nothing; the user must resume. Notification tap does not resume. Lock-screen metadata shows the global session position and only play/pause/stop controls.
- The service remains foreground during an Android pause so a manual lock-screen resume does not require a forbidden background service start. Ending the session publishes idle and stops the port.
- `PreferencesStore` serializes writes to a single JSON preference value. Corrupt fields fall back safely. Playback history is not persisted and startup never starts audio.
- `QuickSleepApp` resolves system language to Chinese or English and supports manual overrides. The session screen keeps the session's original narration language when settings change.
- UI layouts scroll and grow with text. The original Figma orb and selection artwork are bundled, along with locally subsetted, statically instantiated Noto weights. Reduced motion uses a stationary orb.

## Privacy

No account, microphone, location, analytics or network audio. Android debug/profile manifests retain Flutter's development-only Internet permission for debugging; the release manifest has no Internet permission. Files, timing, preferences and media metadata stay on the device.

## Deliberate limits

No seeking, cycle picker, independent voice/music sliders, scoring, remote content, automatic restart or end chime. Only one player is created per app process. The operating system may kill background apps; force-stopped sessions are not restored.

## Recovery and route ownership

`StartupCoordinator` separates retryable preflight work, one-shot native-service initialization and retryable audio-session setup. It coalesces concurrent attempts and keeps the same handler after configuration failures. If the native plugin fails after consuming its single initialization opportunity, the UI asks for a full app restart rather than offering a nonfunctional retry.

A session screen retains its own Route identity. External Stop closes that route; delayed End removes that same route even if Settings has since opened above it. It never blindly pops a newer top route.
