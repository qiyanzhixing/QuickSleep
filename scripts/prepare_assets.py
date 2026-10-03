"""Restore and validate shared bytes; package native resources without Flutter."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import wave
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('restore_assets', ROOT / 'scripts/restore_assets.py')
restore_assets = importlib.util.module_from_spec(spec)
spec.loader.exec_module(restore_assets)

def validate(root):
    entries = json.loads((root / 'audio/catalog.json').read_text(encoding='utf-8'))
    expected = {f'{l}.{m}.{r}' for l in ['zh', 'en'] for m in ['moon', 'mountain', 'forest'] for r in ['guide', 'preview']}
    expected |= {f'shared.{m}.{r}' for m in ['moon', 'mountain', 'forest'] for r in ['bed', 'fade']}
    if len(entries) != 18 or {e['id'] for e in entries} != expected:
        raise ValueError('Incomplete audio catalog')
    for entry in entries:
        path = (root / 'audio' / entry['path']).resolve()
        if not path.is_relative_to((root / 'audio').resolve()) or not entry['provenance']:
            raise ValueError('Unsafe asset or missing provenance')
        if hashlib.sha256(path.read_bytes()).hexdigest() != entry['sha256']:
            raise ValueError('Asset checksum mismatch: ' + entry['id'])
        with wave.open(str(path)) as wav:
            if (wav.getnchannels(), wav.getsampwidth(), wav.getframerate()) != (1, 2, 24000):
                raise ValueError('Unexpected PCM format')
            if wav.getnframes() * 1000 != entry['durationMs'] * 24000:
                raise ValueError('Unexpected PCM duration')

def copy_resources(base):
    shutil.copytree(ROOT / 'shared/assets', base / 'assets', dirs_exist_ok=True)

def prepare(destination=None):
    restore_assets.restore(ROOT / 'shared/asset_bundle', ROOT / 'shared')
    validate(ROOT / 'shared/assets')
    if destination is not None:
        for platform in ['android', 'ios']:
            copy_resources(destination / platform)
        return
    android = ROOT / 'apps/android/app/src/main'
    ios = ROOT / 'apps/ios/QuickSleep/Resources'
    copy_resources(ios)
    shutil.copytree(ROOT / 'shared/assets', android / 'assets', dirs_exist_ok=True)
    fonts = android / 'res/font'
    fonts.mkdir(parents=True, exist_ok=True)
    for source in (ROOT / 'shared/assets/fonts').glob('*.ttf'):
        shutil.copy2(source, fonts / (source.stem.replace('-', '_').lower() + '.ttf'))
    drawings = android / 'res/drawable-nodpi'
    drawings.mkdir(parents=True, exist_ok=True)
    for source in (ROOT / 'shared/assets/visual').glob('*.png'):
        shutil.copy2(source, drawings / source.name)
    for language in ['en', 'zh']:
        values = json.loads((ROOT / f'shared/localization/{language}.json').read_text(encoding='utf-8'))
        values = {k: v for k, v in values.items() if not k.startswith('@')}
        res = android / ('res/values-zh' if language == 'zh' else 'res/values')
        res.mkdir(parents=True, exist_ok=True)
        text = '<resources>\n' + '\n'.join(f'  <string name="{k}" formatted="false">{escape(v).replace(chr(39), chr(92)+chr(39))}</string>' for k, v in values.items()) + '\n</resources>\n'
        (res / 'strings.xml').write_text(text, encoding='utf-8')
        lproj = ios / f'{language}.lproj'
        lproj.mkdir(parents=True, exist_ok=True)
        (lproj / 'Localizable.strings').write_text('\n'.join(f'{json.dumps(k)} = {json.dumps(v, ensure_ascii=False)};' for k, v in values.items()) + '\n', encoding='utf-8')
    print('PASS: 18 audio files, fonts, visuals, licenses and bilingual native resources')

if __name__ == '__main__':
    prepare()
