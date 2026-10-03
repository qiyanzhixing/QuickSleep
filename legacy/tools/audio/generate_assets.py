#!/usr/bin/env python3
"""Generate original beds and pre-mixed bilingual Kokoro guidance, offline at runtime.

Model downloads go to HF_HOME; never package model weights in the app.
"""
import argparse, hashlib, json, subprocess
from pathlib import Path
import numpy as np
import soundfile as sf
from kokoro import KPipeline, KModel
from huggingface_hub import hf_hub_download
import torch

SR=24000
MODES=('moon','mountain','forest')
VOICES={'zh':{'moon':'zf_xiaobei','mountain':'zm_yunjian','forest':'zf_xiaoxiao'},
        'en':{'moon':'af_heart','mountain':'am_michael','forest':'af_sarah'}}
REPOS={'zh':'hexgrad/Kokoro-82M','en':'hexgrad/Kokoro-82M'}
REVISIONS={'zh':'f3ff3571791e39611d31c381e3a41a3af07b4987','en':'f3ff3571791e39611d31c381e3a41a3af07b4987'}

def bed(mode):
    """Periodic synthesis, no samples or external music. 60 seconds at 24kHz."""
    n=60*SR;t=np.arange(n)/SR;rng=np.random.default_rng(480+MODES.index(mode))
    if mode=='moon':
        y=np.zeros(n)
        for freq,gain in [(110,1),(165,.35),(220,.2),(330,.12)]:
            y+=gain*np.sin(2*np.pi*freq*t)*(.72+.28*np.cos(2*np.pi*t/60))
        y*=.045
    elif mode=='mountain':
        y=np.zeros(n)
        for start,freq in [(0,110),(9,146.833333),(20,165),(31,220),(43,146.833333),(52,110)]:
            u=(t-start)%60
            attack=1-np.exp(-u*55)
            for h in range(1,6):
                y+=.10/h**1.8*attack*np.exp(-u/(3.6/h**.3))*np.sin(2*np.pi*round(freq*h*60)/60*u)
    else:
        # A periodic filtered noise bed plus a soft, modulated leaf-rustle band.
        frequencies=np.fft.rfftfreq(n,1/SR)
        spec=rng.normal(size=len(frequencies))+1j*rng.normal(size=len(frequencies))
        shape=1/(1+(frequencies/240)**2)+.055*np.exp(-((frequencies-2100)/1400)**2)
        spec*=shape;spec[0]=0;spec[-1]=0
        y=np.fft.irfft(spec,n)
        y=y/np.max(abs(y))*.13*(.6+.4*np.sin(2*np.pi*t/30)**2)
    return y.astype(np.float32)

def trim(x):
    indices=np.flatnonzero(np.abs(x)>.004)
    if not len(indices): raise ValueError('TTS returned silence')
    return x[max(0,indices[0]-240):min(len(x),indices[-1]+720)]

def fit(x,max_seconds,cache):
    """Use ffmpeg pitch-preserving tempo only when a spoken cue exceeds its slot."""
    limit=int(max_seconds*SR)
    if len(x)>limit:
        sf.write(cache/'tempo-in.wav',x,SR,subtype='FLOAT')
        rate=len(x)/limit
        factors=[]
        while rate>2: factors.append('atempo=2');rate/=2
        factors.append(f'atempo={rate:.8f}')
        subprocess.run(['ffmpeg','-loglevel','error','-y','-i',str(cache/'tempo-in.wav'),'-af',','.join(factors),str(cache/'tempo-out.wav')],check=True)
        x=sf.read(cache/'tempo-out.wav',dtype='float32')[0][:limit]
    x=x.copy();r=min(240,len(x)//2)
    x[:r]*=np.linspace(0,1,r);x[-r:]*=np.linspace(1,0,r)
    peak=np.max(abs(x))
    if peak>0: x=x/peak*.34
    return x

def generate(output,cache):
    output.mkdir(parents=True,exist_ok=True);cache.mkdir(parents=True,exist_ok=True)
    entries=[]
    beds={mode:bed(mode) for mode in MODES}
    def save(locale,mode,role,x,provenance):
        rel=Path('beds' if locale=='shared' else locale)/f'{mode}_{role}.wav'
        p=output/rel;p.parent.mkdir(parents=True,exist_ok=True)
        if len(x)!=SR*({'guide':80,'preview':8,'bed':60,'fade':15}[role]): raise ValueError('Wrong sample count')
        sf.write(p,x,SR,subtype='PCM_16')
        entries.append(dict(id=f'{locale}.{mode}.{role}',path=str(rel),locale=locale,mode=mode,role=role,durationMs=int(len(x)*1000/SR),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),provenance=provenance))
    for mode,b in beds.items():
        save('shared',mode,'bed',b,{'source':'Original deterministic NumPy synthesis','generator':'tools/audio/generate_assets.py','seed':480+MODES.index(mode),'description':'仿古琴合成音' if mode=='mountain' else 'Original synthesized ambience'})
        fade=b[25*SR:40*SR].copy();ramp=np.linspace(1,0,len(fade))**2;ramp[-2400:]=0;fade*=ramp
        save('shared',mode,'fade',fade,{'source':'Original bed samples 25–40 seconds with baked fade','generator':'tools/audio/generate_assets.py'})
    torch.set_num_threads(2)
    for locale in ('zh','en'):
        repo=REPOS[locale]; revision=REVISIONS[locale]
        config=hf_hub_download(repo, 'config.json', revision=revision)
        model=hf_hub_download(repo, KModel.MODEL_NAMES[repo], revision=revision)
        pipeline=KPipeline(lang_code='z' if locale=='zh' else 'a',repo_id=repo,model=KModel(repo_id=repo,config=config,model=model))
        for mode in MODES:
            voice=VOICES[locale][mode];b=beds[mode]
            voice_file=hf_hub_download(repo,f'voices/{voice}.pt',revision=revision)
            voice_pack=torch.load(voice_file,weights_only=True)
            def say(text,seconds):
                key=hashlib.sha256(f'{REPOS[locale]}|{voice}|{text}'.encode()).hexdigest()
                file=cache/f'{key}.wav'
                if file.exists(): x=sf.read(file,dtype='float32')[0]
                else:
                    parts=[r.audio.numpy() for r in pipeline(text,voice=voice_pack,speed=.95) if r.audio is not None]
                    if not parts: raise ValueError(f'No speech for {text}')
                    x=trim(np.concatenate(parts));sf.write(file,x,SR,subtype='FLOAT')
                return fit(x,seconds,cache)
            guide=np.tile(b,2)[40*SR:120*SR].copy()
            guide[:SR]*=np.linspace(0,1,SR)
            cursor=0
            words=['一','二','三','四','五','六','七','八'] if locale=='zh' else ['one','two','three','four','five','six','seven','eight']
            phases=['吸气','屏息','呼气'] if locale=='zh' else ['In','Hold','Out']
            for cycle in range(4):
                for phase,count in zip(phases,[4,7,8]):
                    for i in range(count):
                        text=f'{phase}，{words[i]}' if i==0 else words[i]
                        x=say(text,.88);guide[cursor*SR:cursor*SR+len(x)]+=x;cursor+=1
            x=say('现在，恢复自然呼吸。' if locale=='zh' else 'Now, breathe naturally.',3.6)
            guide[76*SR:76*SR+len(x)]+=x
            provenance={'source':REPOS[locale],'revision':REVISIONS[locale],'voiceSha256':hashlib.sha256(Path(voice_file).read_bytes()).hexdigest(),'license':'Apache-2.0','voice':voice,'engine':'kokoro 0.9.4','synthetic':True,'timing':'4 rounds of 4+7+8 seconds; 4-second transition','originalBackground':mode}
            save(locale,mode,'guide',guide,provenance)
            preview=b[:8*SR].copy();preview[:SR]*=np.linspace(0,1,SR);preview[-SR:]*=np.linspace(1,0,SR)
            x=say('让呼吸慢下来，轻轻放松。' if locale=='zh' else 'Slow your breathing, and gently relax.',6)
            preview[SR:SR+len(x)]+=x
            save(locale,mode,'preview',preview,provenance)
            print(f'Generated {locale}.{mode}',flush=True)
    (output/'catalog.json').write_text(json.dumps(entries,ensure_ascii=False,indent=2)+'\n')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--output',type=Path,default=Path('assets/audio'));p.add_argument('--cache',type=Path,default=Path('.audio-cache'))
    args=p.parse_args();generate(args.output,args.cache)
