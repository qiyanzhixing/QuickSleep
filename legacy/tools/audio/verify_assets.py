#!/usr/bin/env python3
"""Verify offline PCM assets, their catalog and seamless join points."""
import hashlib
import json
from pathlib import Path
import sys
import wave
import numpy as np

EXPECTED = {'guide':80000,'preview':8000,'bed':60000,'fade':15000}

def read_pcm(path):
    with wave.open(str(path),'rb') as w:
        if (w.getnchannels(),w.getsampwidth(),w.getframerate()) != (1,2,24000):
            raise ValueError(f'{path}: expected mono PCM16 at 24000 Hz')
        return np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(np.float64)/32768

def verify(root):
    root=Path(root)
    entries=json.loads((root/'catalog.json').read_text())
    expected={f'{locale}.{mode}.{role}' for locale in ['zh','en'] for mode in ['moon','mountain','forest'] for role in ['guide','preview']}
    expected|={f'shared.{mode}.{role}' for mode in ['moon','mountain','forest'] for role in ['bed','fade']}
    if len(entries)!=18 or {e['id'] for e in entries}!=expected: raise ValueError('Expected 18 unique assets')
    waves={}
    for e in entries:
        if not e['provenance']: raise ValueError('Missing provenance')
        p=(root/e['path']).resolve()
        if root.resolve() not in p.parents: raise ValueError('Unsafe asset path')
        if hashlib.sha256(p.read_bytes()).hexdigest()!=e['sha256']: raise ValueError(f'{p}: checksum mismatch')
        x=read_pcm(p); waves[e['id']]=x
        measured=len(x)*1000/24000
        if e['durationMs']!=EXPECTED[e['role']] or abs(measured-e['durationMs'])>20: raise ValueError(f'{p}: incorrect duration')
        if np.max(np.abs(x))>=10**(-1/20): raise ValueError(f'{p}: peak exceeds -1 dBFS')
        if np.sqrt(np.mean(x*x))<0.001: raise ValueError(f'{p}: silent asset')
        if e['role']=='fade' and np.sqrt(np.mean(x[-2400:]**2))>=0.001: raise ValueError(f'{p}: non-silent ending')
    for mode in ['moon','mountain','forest']:
        bed=waves[f'shared.{mode}.bed']; fade=waves[f'shared.{mode}.fade']
        joins=[(bed[-1],bed[0]),(bed[25*24000-1],fade[0])]
        joins += [(waves[f'{locale}.{mode}.guide'][-1],bed[0]) for locale in ['zh','en']]
        if any(abs(a-b)>=0.01 for a,b in joins): raise ValueError(f'{mode}: discontinuity at splice')
    return entries

if __name__=='__main__':
    result=verify(sys.argv[1] if len(sys.argv)>1 else 'assets/audio')
    print(f'PASS: {len(result)} assets; durations, hashes, peaks, fades and splice samples verified')
