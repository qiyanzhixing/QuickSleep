"""Install portable build tools inside the repository (not system-wide)."""
import json
import os
from pathlib import Path
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / '.tools'

def download(url, target):
    if not target.exists():
        print('Downloading', target.name, flush=True)
        with urllib.request.urlopen(url, timeout=120) as response, target.open('wb') as output:
            while chunk := response.read(1024 * 1024):
                output.write(chunk)

def install():
    TOOLS.mkdir(exist_ok=True)
    if not (TOOLS / 'jdk').exists():
        url = 'https://cdn.azul.com/zulu/bin/zulu17.60.17-ca-jdk17.0.16-win_x64.zip'
        archive = TOOLS / 'jdk.zip'
        download(url, archive)
        with zipfile.ZipFile(archive) as zipped:
            directory = zipped.namelist()[0].split('/')[0]
            zipped.extractall(TOOLS)
        (TOOLS / directory).rename(TOOLS / 'jdk')
    if not (TOOLS / 'gradle-8.13').exists():
        archive = TOOLS / 'gradle.zip'
        url = 'https://downloads.gradle.org/distributions/gradle-8.13-bin.zip'
        download(url, archive)
        import hashlib
        with urllib.request.urlopen(url + '.sha256', timeout=60) as response:
            digest = response.read().decode().strip()
        if hashlib.sha256(archive.read_bytes()).hexdigest() != digest:
            raise ValueError('Gradle checksum mismatch')
        with zipfile.ZipFile(archive) as zipped:
            zipped.extractall(TOOLS)
    if not (TOOLS / 'android-sdk/cmdline-tools/latest/bin/sdkmanager.bat').exists():
        archive = TOOLS / 'android-tools.zip'
        download('https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip', archive)
        sdk = TOOLS / 'android-sdk'
        sdk.mkdir(exist_ok=True)
        with zipfile.ZipFile(archive) as zipped:
            zipped.extractall(sdk)
        (sdk / 'cmdline-tools').rename(sdk / 'unpacked')
        (sdk / 'cmdline-tools').mkdir()
        (sdk / 'unpacked').rename(sdk / 'cmdline-tools/latest')
    print('Portable Android tools ready:', TOOLS, flush=True)

if __name__ == '__main__':
    install()
