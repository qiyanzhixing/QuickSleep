#!/usr/bin/env python3
"""Restore exact bundled assets using Python's standard library, without network.

All source chunks, archive and output files are verified before any file is
written. Run this before flutter pub get, or use `make setup`.
"""
import argparse,hashlib,io,json,re,tarfile,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sha(data):return hashlib.sha256(data).hexdigest()
def expected_files(manifest):
 files={}
 for e in manifest['files']:
  path=e['path']
  if not re.fullmatch(r'assets/(audio/(zh|en|beds)/[a-z_]+\.wav|fonts/[A-Za-z-]+\.ttf)',path):
   raise ValueError('Unsafe output path')
  if path in files or not re.fullmatch(r'[a-f0-9]{64}',e['sha256']) or not 0<e['size']<8000000:
   raise ValueError('Invalid asset metadata')
  files[path]=e
 if len(files)!=21:raise ValueError('Expected 18 audio files and 3 fonts')
 return files

def restore(bundle,output,check=False):
 manifest=json.loads((bundle/'manifest.json').read_text());files=expected_files(manifest)
 if check:
  for name,e in files.items():
   if sha((output/name).read_bytes())!=e['sha256']:raise ValueError('Output hash mismatch: '+name)
  return len(files)
 archive_bytes=bytearray();seen=set()
 for part in manifest['parts']:
  name=part['name']
  if not re.fullmatch(r'part-[0-9]{4}\.bin',name) or name in seen:raise ValueError('Invalid part name')
  seen.add(name);data=(bundle/name).read_bytes()
  if len(data)!=part['size'] or sha(data)!=part['sha256']:raise ValueError('Part hash mismatch: '+name)
  archive_bytes.extend(data)
  if len(archive_bytes)>64000000:raise ValueError('Oversized archive')
 if sha(archive_bytes)!=manifest['archiveSha256']:raise ValueError('Archive hash mismatch')
 verified={}
 with tarfile.open(fileobj=io.BytesIO(archive_bytes),mode='r:xz') as archive:
  for member in archive:
   if not member.isfile() or member.name not in files or member.name in verified:raise ValueError('Unexpected archive member')
   e=files[member.name]
   if member.size!=e['size']:raise ValueError('Asset size mismatch')
   stream=archive.extractfile(member)
   if stream is None:raise ValueError('Missing asset bytes')
   data=stream.read(e['size']+1)
   if sha(data)!=e['sha256']:raise ValueError('Asset hash mismatch: '+member.name)
   target=(output/member.name).resolve()
   if not target.is_relative_to(output.resolve()):raise ValueError('Output escapes destination')
   verified[member.name]=data
 if set(verified)!=set(files):raise ValueError('Incomplete asset archive')
 # No writes occur before the complete input set has passed validation.
 for name,data in verified.items():
  target=output/name
  if target.exists() and sha(target.read_bytes())==files[name]['sha256']:continue
  target.parent.mkdir(parents=True,exist_ok=True)
  # Exclusive creation avoids following an attacker-controlled temporary symlink.
  temporary=None
  try:
   with tempfile.NamedTemporaryFile(dir=target.parent,prefix='.'+target.name+'.',suffix='.restore-tmp',delete=False) as stream:
    temporary=Path(stream.name);stream.write(data)
   temporary.replace(target)
  finally:
   if temporary is not None:temporary.unlink(missing_ok=True)
 return len(files)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--bundle',type=Path,default=ROOT/'asset_bundle');p.add_argument('--output',type=Path,default=ROOT);p.add_argument('--check',action='store_true');a=p.parse_args()
 print(f'PASS: {restore(a.bundle,a.output,a.check)} exact offline assets '+('verified' if a.check else 'restored'))
