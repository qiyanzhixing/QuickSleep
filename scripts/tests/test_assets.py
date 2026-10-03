import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import wave
import array
import math
import shutil

ROOT = Path(__file__).resolve().parents[2]

class NativeAssetsTests(unittest.TestCase):
    def module(self):
        spec = importlib.util.spec_from_file_location('prepare', ROOT / 'scripts/prepare_assets.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_corrupted_bundle_rejected_before_writes(self):
        module = self.module()
        with tempfile.TemporaryDirectory() as directory:
            bundle = Path(directory) / 'bundle'
            shutil.copytree(ROOT / 'shared/asset_bundle', bundle)
            part = bundle / 'part-0000.bin'
            data = bytearray(part.read_bytes())
            data[0] ^= 1
            part.write_bytes(data)
            output = Path(directory) / 'output'
            with self.assertRaisesRegex(ValueError, 'Part hash mismatch'):
                module.restore_assets.restore(bundle, output)
            self.assertFalse(output.exists())

    def test_audio_amplitude_fade_and_splices(self):
        entries = json.loads((ROOT / 'shared/assets/audio/catalog.json').read_text(encoding='utf-8'))
        waves = {}
        for entry in entries:
            with wave.open(str(ROOT / 'shared/assets/audio' / entry['path'])) as wav:
                samples = array.array('h', wav.readframes(wav.getnframes()))
            waves[entry['id']] = samples
            self.assertLess(max(abs(s) for s in samples) / 32768, 10 ** (-1/20))
            self.assertGreater(math.sqrt(sum(s*s for s in samples) / len(samples)) / 32768, 0.001)
            if entry['role'] == 'fade':
                tail = samples[-2400:]
                self.assertLess(math.sqrt(sum(s*s for s in tail) / len(tail)) / 32768, 0.001)
        for mode in ['moon', 'mountain', 'forest']:
            bed, fade = waves[f'shared.{mode}.bed'], waves[f'shared.{mode}.fade']
            pairs = [(bed[-1], bed[0]), (bed[25*24000-1], fade[0])]
            pairs += [(waves[f'{language}.{mode}.guide'][-1], bed[0]) for language in ['zh', 'en']]
            for before, after in pairs:
                self.assertLess(abs(before-after) / 32768, 0.01)

    def test_localization_key_parity(self):
        values = [json.loads((ROOT / f'shared/localization/{language}.json').read_text(encoding='utf-8')) for language in ['zh', 'en']]
        keys = [{k for k in value if not k.startswith('@')} for value in values]
        self.assertEqual(keys[0], keys[1])
        self.assertTrue(all(isinstance(v[k], str) and v[k] for v in values for k in keys[0]))

    def test_prepare_native_assets(self):
        module = self.module()
        with tempfile.TemporaryDirectory() as directory:
            destination = Path(directory)
            module.prepare(destination)
            for platform in ['android', 'ios']:
                base = destination / platform
                catalog = json.loads((base / 'assets/audio/catalog.json').read_text(encoding='utf-8'))
                self.assertEqual(len(catalog), 18)
                for entry in catalog:
                    audio = base / 'assets/audio' / entry['path']
                    self.assertEqual(hashlib.sha256(audio.read_bytes()).hexdigest(), entry['sha256'])
                    with wave.open(str(audio)) as wav:
                        self.assertEqual((wav.getnchannels(), wav.getsampwidth(), wav.getframerate()), (1, 2, 24000))
                        self.assertEqual(wav.getnframes() * 1000 // 24000, entry['durationMs'])
                self.assertEqual(len(list((base / 'assets/fonts').glob('*.ttf'))), 3)
                self.assertTrue((base / 'assets/visual/orb_night.png').exists())

if __name__ == '__main__':
    unittest.main()
