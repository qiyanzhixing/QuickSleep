import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../audio/session_audio_handler.dart';
import '../l10n/generated/app_localizations.dart';
import '../session/session_plan.dart';
import '../theme/app_theme.dart';

String modeName(AppLocalizations l, SoundMode mode) => switch (mode) {
  SoundMode.moon => l.modeMoon,
  SoundMode.mountain => l.modeMountain,
  SoundMode.forest => l.modeForest,
};
String modeDescription(AppLocalizations l, SoundMode mode) => switch (mode) {
  SoundMode.moon => l.descMoon,
  SoundMode.mountain => l.descMountain,
  SoundMode.forest => l.descForest,
};
Future<void> showSoundModeSheet(
  BuildContext context, {
  required SessionAudioHandler audio,
  required SoundMode selected,
  required AppLanguage language,
  required ValueChanged<SoundMode> onChanged,
}) async {
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: context.colors.background.withValues(alpha: .78),
      builder: (_) => SoundModeSheet(
        audio: audio,
        selected: selected,
        language: language,
        onChanged: onChanged,
      ),
    );
  } finally {
    await audio.stopPreview();
  }
}

class SoundModeSheet extends StatefulWidget {
  const SoundModeSheet({
    super.key,
    required this.audio,
    required this.selected,
    required this.language,
    required this.onChanged,
  });
  final SessionAudioHandler audio;
  final SoundMode selected;
  final AppLanguage language;
  final ValueChanged<SoundMode> onChanged;
  @override
  State<SoundModeSheet> createState() => _SoundModeSheetState();
}

class _SoundModeSheetState extends State<SoundModeSheet> {
  late SoundMode selected = widget.selected;
  @override
  void dispose() {
    unawaited(widget.audio.stopPreview());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = context.colors;
    return SizedBox(
      height: math.min(628, MediaQuery.sizeOf(context).height * .9),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.muted,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.soundMode,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const ValueKey('close_sound'),
                  onPressed: () => Navigator.pop(context),
                  tooltip: l.close,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l.soundHint, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            StreamBuilder<PreviewSnapshot>(
              stream: widget.audio.previewStates,
              initialData: widget.audio.previewStates.value,
              builder: (context, snapshot) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final mode in SoundMode.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                        selected: mode == selected,
                        child: Material(
                          color: mode == selected ? c.surface : c.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: mode == selected ? c.accent : c.border,
                              width: mode == selected ? 1.5 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            key: ValueKey('mode_${mode.name}'),
                            onTap: () {
                              setState(() => selected = mode);
                              widget.onChanged(mode);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/visual/${mode == selected ? 'selected' : 'unselected'}_${context.assetTheme}.png',
                                        width: 20,
                                        height: 20,
                                        excludeFromSemantics: true,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          modeName(l, mode),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelLarge,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 100,
                                        ),
                                        child: TextButton(
                                          key: ValueKey('preview_${mode.name}'),
                                          onPressed: () =>
                                              snapshot.data?.mode == mode
                                              ? widget.audio.stopPreview()
                                              : widget.audio.preview(
                                                  mode,
                                                  widget.language,
                                                ),
                                          child: Text(
                                            snapshot.data?.mode == mode
                                                ? '□ ${l.stopPreview}'
                                                : '▷ ${l.preview}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: c.accent,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(modeDescription(l, mode)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (snapshot.data?.error != null)
                    Text(
                      l.previewError,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.mixedHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}
