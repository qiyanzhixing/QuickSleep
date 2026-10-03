import unittest
from pathlib import Path
import sys, json, tempfile, shutil
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools/audio'))

class AssetsTest(unittest.TestCase):
    def test_catalog_has_eighteen_valid_assets(self):
        self.assertTrue((ROOT/'assets/audio/catalog.json').exists(), 'Bundled audio catalog is required')
        from verify_assets import verify
        entries=verify(ROOT/'assets/audio')
        self.assertEqual(len(entries),18)
        self.assertEqual(sorted(x['durationMs'] for x in entries), sorted([80000]*6+[8000]*6+[60000]*3+[15000]*3))

    def test_validation_rejects_tampering(self):
        self.assertTrue((ROOT/'assets/audio/catalog.json').exists(), 'Real assets are required for corruption checks')
        from verify_assets import verify
        for kind in ['missing','checksum','duration']:
            with self.subTest(kind=kind), tempfile.TemporaryDirectory() as tmp:
                dest=Path(tmp)/'audio'; shutil.copytree(ROOT/'assets/audio',dest)
                catalog=json.loads((dest/'catalog.json').read_text()); first=catalog[0]
                if kind=='missing': (dest/first['path']).unlink()
                elif kind=='checksum': first['sha256']='0'*64
                else: first['durationMs']+=1000
                (dest/'catalog.json').write_text(json.dumps(catalog))
                with self.assertRaises((ValueError,FileNotFoundError)):
                    verify(dest)

if __name__=='__main__': unittest.main()
