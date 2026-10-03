#!/usr/bin/env python3
"""Subset official Google Fonts to app text and instantiate stable 400/500 weights.
Usage: python3 tools/prepare_fonts.py --source <directory containing full TTFs>
Download NotoSansSC[wght].ttf and NotoSerifSC[wght].ttf from google/fonts,
and name them NotoSansSC-full.ttf and NotoSerifSC-full.ttf. Keep OFL notices.
"""
import argparse,hashlib,json
from pathlib import Path
from fontTools import subset
from fontTools.varLib.instancer import instantiateVariableFont

def prepare(source,root):
 text=''.join(chr(c) for c in range(32,255))+'▷□›×–—·'
 for p in (root/'lib/l10n').glob('*.arb'):
  text+=''.join(str(v) for k,v in json.loads(p.read_text()).items() if not k.startswith('@'))
 records=[]
 for family,weight,filename in [('NotoSansSC',400,'NotoSansSC.ttf'),('NotoSansSC',500,'NotoSansSC-Medium.ttf'),('NotoSerifSC',400,'NotoSerifSC.ttf')]:
  original=source/f'{family}-full.ttf';path=root/'assets/fonts'/filename
  options=subset.Options();options.layout_features=['*'];options.name_IDs=['*'];options.name_legacy=True;options.name_languages=['*']
  font=subset.load_font(str(original),options)
  instantiateVariableFont(font,{'wght':weight},inplace=True)
  sub=subset.Subsetter(options=options);sub.populate(text=text);sub.subset(font);subset.save_font(font,str(path),options)
  records.append(dict(file=filename,weight=weight,source=f'https://github.com/google/fonts/tree/main/ofl/{family.lower()}',sourceSha256=hashlib.sha256(original.read_bytes()).hexdigest(),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),modifications='Glyph subset and static weight instantiation',license='SIL OFL 1.1'))
 (root/'assets/licenses/font-sources.json').write_text(json.dumps(records,indent=2)+'\n')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);a=p.parse_args();prepare(a.source,Path(__file__).resolve().parents[1])
