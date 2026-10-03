"""Run native Android smoke checks on an explicitly selected disposable emulator.

Exercises real playback and captures screens; not a substitute for phone acceptance.
"""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = 'com.qiyanzhixing.quicksleep'

class Smoke:
    def __init__(self, adb, serial):
        self.adb = str(adb)
        self.serial = serial
        self.results = []
        self.output = ROOT / 'docs/screenshots/native'
        self.output.mkdir(parents=True, exist_ok=True)

    def command(self, *args):
        return subprocess.check_output([self.adb, '-s', self.serial, *args], text=True, encoding='utf-8', errors='replace')

    def ui(self):
        self.command('shell', 'uiautomator', 'dump', '/sdcard/quicksleep-ui.xml')
        return ET.fromstring(self.command('exec-out', 'cat', '/sdcard/quicksleep-ui.xml'))

    def tap(self, label=None, kind=None, occurrence=0):
        for _ in range(5):
            tree = self.ui()
            parents = {child: parent for parent in tree.iter() for child in parent}
            nodes = [node for node in tree.iter('node') if (label is None or label in [node.get('text'), node.get('content-desc')]) and (kind is None or node.get('class') == kind)]
            if len(nodes) > occurrence: break
            self.command('shell', 'input', 'swipe', '540', '1600', '540', '900', '350')
            time.sleep(0.2)
        if len(nodes) <= occurrence:
            raise AssertionError(f'Missing UI control: {label or kind}; visible: {[n.get("text") for n in tree.iter("node") if n.get("text")]}')
        node = nodes[occurrence]
        while node.get('clickable') != 'true' and node in parents:
            node = parents[node]
        x1, y1, x2, y2 = map(int, re.findall(r'\d+', node.get('bounds')))
        self.command('shell', 'input', 'tap', str((x1+x2)//2), str((y1+y2)//2))
        time.sleep(0.3)

    def capture(self, name):
        remote = f'/sdcard/{name}.png'
        self.command('shell', 'screencap', '-p', remote)
        self.command('pull', remote, str(self.output / f'{name}.png'))

    def media(self):
        return self.command('shell', 'dumpsys', 'media_session')

    @staticmethod
    def state(value, number):
        return bool(re.search(rf'state=(?:[A-Z_]+\()?{number}(?:\)|[, ])', value))

    def record(self, name, condition, detail=''):
        if not condition:
            raise AssertionError(f'{name}: {detail}')
        self.results.append({'check': name, 'result': 'passed', 'detail': detail})
        print('PASS:', name, detail, flush=True)

    def wait_media(self, number, timeout=15):
        start = time.monotonic()
        while time.monotonic() - start < timeout:
            value = self.media()
            if self.state(value, number): return value
            time.sleep(0.5)
        raise AssertionError('Missing media state: ' + str(number) + '\n' + value)

    def run(self, apk):
        self.command('install', '-r', str(apk))
        self.command('shell', 'am', 'force-stop', PACKAGE)
        self.command('shell', 'am', 'start', '-n', PACKAGE + '/.MainActivity')
        time.sleep(2)
        labels = [n.get('content-desc') for n in self.ui().iter('node')]
        self.tap('Settings' if 'Settings' in labels else '设置')
        self.tap('简体中文')
        self.tap('夜间')
        self.tap('关闭')
        self.capture('android-night-home')
        self.tap('声音模式')
        self.tap('林间晚风')
        self.capture('android-night-sounds')
        self.tap('试听', occurrence=2)
        self.wait_media(3)
        self.tap('关闭')
        self.record('Closing sound sheet stops preview', not self.state(self.media(), 3))
        self.tap('自定义')
        self.tap(kind='android.widget.EditText')
        self.command('shell', 'input', 'keyevent', '123')
        self.command('shell', 'input', 'keyevent', '67')
        self.command('shell', 'input', 'keyevent', '67')
        self.command('shell', 'input', 'text', '2')
        self.tap('保存')
        self.tap('开始放松')
        active = self.wait_media(3)
        self.record('Finite native item exposes full 2-minute duration', '120000' in active, active[-1500:])
        self.capture('android-night-session')
        self.tap('暂停')
        paused = self.wait_media(2)
        first = re.search(r'position=(\d+)', paused)
        time.sleep(3)
        second = re.search(r'position=(\d+)', self.media())
        self.record('Paused playback consumes no session time', first and second and first.group(1) == second.group(1))
        self.tap('继续')
        self.wait_media(3)
        self.command('shell', 'input', 'keyevent', '3')
        start = time.monotonic()
        self.record('Playback continues with Activity backgrounded', self.state(self.media(), 3))
        while time.monotonic() - start < 135:
            if not self.state(self.media(), 3): break
            time.sleep(2)
        media = self.media()
        self.record('Finite background playback ends without UI timer', not self.state(media, 3))
        self.command('shell', 'am', 'start', '-n', PACKAGE + '/.MainActivity')
        time.sleep(1)
        labels = [n.get('text') for n in self.ui().iter('node')]
        self.record('Foreground observes completed session', '安静休息吧' in labels)
        self.tap('返回准备页')
        self.command('shell', 'am', 'force-stop', PACKAGE)
        self.command('shell', 'am', 'start', '-n', PACKAGE + '/.MainActivity')
        time.sleep(1)
        self.record('Force-stop restart stays silent', not self.state(self.media(), 3))
        self.capture('android-final-home')
        (ROOT / '.tools/android-smoke-results.json').write_text(json.dumps(self.results, ensure_ascii=False, indent=2), encoding='utf-8')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--serial', required=True)
    parser.add_argument('--adb', type=Path, default=ROOT / '.tools/android-sdk/platform-tools/adb.exe')
    parser.add_argument('--apk', type=Path, default=ROOT / 'apps/android/app/build/outputs/apk/debug/app-debug.apk')
    args = parser.parse_args()
    if not args.serial.startswith('emulator-'):
        parser.error('Use a disposable emulator; this script force-stops the test app.')
    os.environ['ANDROID_USER_HOME'] = str(ROOT / '.tools/android-user')
    Smoke(args.adb, args.serial).run(args.apk)
