#!/usr/bin/env python3
"""Package already-verified WAVs/fonts losslessly for bounded repository uploads."""
import hashlib,io,json,tarfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(data):return hashlib.sha256(data).hexdigest()
def main():
 files=[]
 for e in json.loads((ROOT/'assets/audio/catalog.json').read_text()):
  files.append({'path':'assets/audio/'+e['path'],'sha256':e['sha256']})
 for e in json.loads((ROOT/'assets/licenses/font-sources.json').read_text()):
  files.append({'path':'assets/fonts/'+e['file'],'sha256':e['sha256']})
 buffer=io.BytesIO()
 with tarfile.open(fileobj=buffer,mode='w:xz',preset=6) as archive:
  for e in sorted(files,key=lambda x:x['path']):
   data=(ROOT/e['path']).read_bytes()
   if sha(data)!=e['sha256']:raise ValueError('Source hash mismatch: '+e['path'])
   e['size']=len(data);info=tarfile.TarInfo(e['path']);info.size=len(data);info.mode=0o644;info.mtime=0
   archive.addfile(info,io.BytesIO(data))
 data=buffer.getvalue();dest=ROOT/'asset_bundle';dest.mkdir(exist_ok=True);parts=[]
 for i,start in enumerate(range(0,len(data),65536)):
  part=data[start:start+65536];name=f'part-{i:04}.bin';(dest/name).write_bytes(part)
  parts.append(dict(name=name,size=len(part),sha256=sha(part)))
 names={p['name'] for p in parts}
 for old in dest.glob('part-*.bin'):
  if old.name not in names:old.unlink()
 manifest=dict(format=1,archive='tar.xz',archiveSha256=sha(data),parts=parts,files=files)
 (dest/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 print(f'Packed {len(files)} exact assets into {len(parts)} parts ({len(data)} bytes)')
if __name__=='__main__':main()
