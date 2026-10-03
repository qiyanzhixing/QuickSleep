import hashlib,json,subprocess,sys,tempfile,unittest,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
class RestoreAssetsTest(unittest.TestCase):
 def test_existing_temporary_symlink_cannot_escape_output(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d);output=root/'output';target=output/'assets/audio/beds/forest_bed.wav'
   target.parent.mkdir(parents=True);sentinel=root/'sentinel';sentinel.write_bytes(b'untouched')
   target.with_suffix('.wav.restore-tmp').symlink_to(sentinel)
   result=subprocess.run([sys.executable,str(ROOT/'tools/restore_assets.py'),'--output',str(output)],capture_output=True,text=True)
   self.assertEqual(result.returncode,0,result.stderr)
   self.assertEqual(sentinel.read_bytes(),b'untouched')
   self.assertFalse(target.is_symlink())
   manifest=json.loads((ROOT/'asset_bundle/manifest.json').read_text())
   expected=next(e for e in manifest['files'] if e['path']=='assets/audio/beds/forest_bed.wav')
   self.assertEqual(hashlib.sha256(target.read_bytes()).hexdigest(),expected['sha256'])
 def test_restores_exact_original_bytes(self):
  self.assertTrue((ROOT/'tools/restore_assets.py').exists(),'A restore helper is required')
  with tempfile.TemporaryDirectory() as d:
   result=subprocess.run([sys.executable,str(ROOT/'tools/restore_assets.py'),'--output',d],capture_output=True,text=True)
   self.assertEqual(result.returncode,0,result.stderr)
   for e in json.loads((ROOT/'asset_bundle/manifest.json').read_text())['files']:
    self.assertEqual(hashlib.sha256((Path(d)/e['path']).read_bytes()).hexdigest(),e['sha256'])
 def test_corrupt_chunk_is_rejected_without_writing_assets(self):
  self.assertTrue((ROOT/'tools/restore_assets.py').exists(),'A restore helper is required')
  with tempfile.TemporaryDirectory() as d:
   pack=Path(d)/'pack';shutil.copytree(ROOT/'asset_bundle',pack)
   manifest=json.loads((pack/'manifest.json').read_text());part=pack/manifest['parts'][0]['name'];part.write_bytes(b'corrupt')
   output=Path(d)/'output'
   result=subprocess.run([sys.executable,str(ROOT/'tools/restore_assets.py'),'--bundle',str(pack),'--output',str(output)],capture_output=True,text=True)
   self.assertNotEqual(result.returncode,0);self.assertFalse((output/'assets').exists())
 def test_missing_files_fail_check(self):
  self.assertTrue((ROOT/'tools/restore_assets.py').exists(),'A restore helper is required')
  with tempfile.TemporaryDirectory() as d:
   result=subprocess.run([sys.executable,str(ROOT/'tools/restore_assets.py'),'--output',d,'--check'],capture_output=True,text=True)
   self.assertNotEqual(result.returncode,0)
