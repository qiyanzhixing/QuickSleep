# Bundled audio and visual sources

## Voice

All six guide/preview pairs are pre-generated synthetic speech with [hexgrad/Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M), revision `f3ff3571791e39611d31c381e3a41a3af07b4987`, Apache-2.0. The application contains only finished WAVs, not model weights or a TTS engine.

| Mode | Chinese voice | English voice |
| --- | --- | --- |
| Moonlit Whispers / 月下轻语 | zf_xiaobei | af_heart |
| Mountain Stillness / 山间静心 | zm_yunjian | am_michael |
| Forest Evening Breeze / 林间晚风 | zf_xiaoxiao | af_sarah |

The proposed Chinese v1.1 model was evaluated first. Short breathing cues were poorly recognized, so the final Chinese assets use v1.0, whose uncompressed cue checks were clearer. Short repetitive counting is difficult for ASR; see the diagnostic machine transcripts. **Human listening approval is still pending.** Gender/style descriptions refer to the synthetic voice presets and should be auditioned on a phone.

Generator: Python 3.12, CPU torch 2.8.0, kokoro 0.9.4, misaki 0.9.4, NumPy 2.5.3, soundfile 0.14.0, ffmpeg. Generation-only dependencies and their distributions retain their respective upstream licenses (Kokoro Apache-2.0; Misaki MIT; PyTorch BSD; NumPy BSD; SoundFile BSD; ffmpeg LGPL/GPL according to the installed build). No engine, model, phonemizer or ffmpeg binary is shipped in the app.

The generator pins the model revision and records voice-file SHA256 values. `shared/assets/licenses/model-sources.json` records the exact model/config/voice hashes; the Apache license is bundled. Every finished asset has its own SHA256 and provenance in `shared/assets/audio/catalog.json`.

## Original backgrounds

The historical `legacy/tools/audio/generate_assets.py` synthesized these without external music or samples:

- Moon: low-level harmonic sine ambience with a periodic amplitude envelope
- Mountain: sparse, decaying, harmonically synthesized plucks, explicitly **仿古琴合成音 / guqin-inspired synthesis**
- Forest: periodic filtered noise and a modulated rustle band

Beds are 60 seconds. Guides use a phase-aligned 80-second bed underneath exactly four 19-second rounds and a four-second natural-breathing transition. A 15-second tail uses samples 25–40 of the same bed, with a quadratic fade and a silent final 100 ms. The native clients assemble these PCM WAV samples into one finite file to avoid encoder priming/padding ambiguity.

There are six 80-second guides, six 8-second previews, three 60-second beds and three 15-second tails. Speech cues are cached, silence-trimmed, normalized and tempo-fitted only if longer than their one-second slot. These timing transformations are a reason to review actual listening quality, not merely duration.

## Artwork and fonts

The user's approved Figma file: [QuickSleep](https://www.figma.com/design/YhCQWQVZnqfYYZjZJMx44S?node-id=5-8). Original orb, lock and selection-indicator nodes were exported directly without redrawing. Night/Light theme values came from resolved variables and screenshots. No full-screen screenshot is used as UI.

Noto Sans SC (regular 400 / medium 500) and Noto Serif SC (regular 400) come from [Google Fonts](https://github.com/google/fonts), under the bundled SIL OFL 1.1 notices. Variable sources were instantiated to static weights and subsetted to the app's Chinese/English text plus common Latin characters. The source/output hashes and modifications are recorded in `shared/assets/licenses/font-sources.json`. The original font-generation tool is preserved in `legacy/tools/prepare_fonts.py`; adding characters outside the subset requires intentionally regenerating and repackaging shared fonts. Font generation requires `fonttools`.

## Lossless source packaging

Finished WAVs and fonts are stored in `shared/asset_bundle` as bounded binary parts of one lossless tar.xz archive. `scripts/restore_assets.py` verifies each part, the archive, every allowed path, size and final file SHA256 before writing anything. The restored WAV/font bytes are identical to the historical inputs. Restoration uses Python's standard library and no network/model engine. Run `python scripts/prepare_assets.py` after checkout; native CI jobs restore automatically. Missing or corrupt parts fail loudly. The historical generation/packaging tools remain in `legacy/tools`; shared-source changes must update the shared bundle, hashes and catalog together. Native builds only restore finished bytes.
