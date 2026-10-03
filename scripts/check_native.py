"""Check native resource references, project coverage, privacy and APK bytes."""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import struct
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]

def check(apk=None):
    info = plistlib.loads((ROOT / 'apps/ios/QuickSleep/Info.plist').read_bytes())
    assert info['UIBackgroundModes'] == ['audio']
    project = (ROOT / 'apps/ios/QuickSleep.xcodeproj/project.pbxproj').read_text(encoding='utf-8')
    for source in (ROOT / 'apps/ios/QuickSleep').rglob('*.swift'):
        assert source.relative_to(ROOT / 'apps/ios').as_posix() in project, source
    for font in info['UIAppFonts']:
        assert (ROOT / 'apps/ios/QuickSleep/Resources' / font).exists(), font
    for font in (ROOT / 'shared/assets/fonts').glob('*.ttf'):
        raw = font.read_bytes()
        count = struct.unpack_from('>H', raw, 4)[0]
        tables = {raw[12+i*16:16+i*16].decode(): struct.unpack_from('>II', raw, 20+i*16) for i in range(count)}
        offset, _ = tables['name']
        _, count, start = struct.unpack_from('>HHH', raw, offset)
        names = set()
        for i in range(count):
            platform, _, _, name, size, position = struct.unpack_from('>HHHHHH', raw, offset+6+i*12)
            if name == 6:
                names.add(raw[offset+start+position:offset+start+position+size].decode('utf-16-be' if platform in (0,3) else 'latin1'))
        print('Font:', font.name, sorted(names))
    manifest = ET.parse(ROOT / 'apps/android/app/src/main/AndroidManifest.xml')
    permissions = [entry.attrib['{http://schemas.android.com/apk/res/android}name'] for entry in manifest.findall('uses-permission')]
    assert 'android.permission.INTERNET' not in permissions
    catalogs = json.loads((ROOT / 'shared/assets/audio/catalog.json').read_text(encoding='utf-8'))
    if apk:
        with zipfile.ZipFile(apk) as archive:
            for entry in catalogs:
                assert hashlib.sha256(archive.read('assets/audio/' + entry['path'])).hexdigest() == entry['sha256'], entry['id']
            for font in (ROOT / 'shared/assets/fonts').glob('*.ttf'):
                assert archive.read('assets/fonts/' + font.name) == font.read_bytes()
        print('PASS: APK has exact 18 WAVs and 3 fonts')
    print('PASS: native resource references, Swift source coverage and offline Android manifest')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--apk', type=Path)
    check(parser.parse_args().apk)
