#!/usr/bin/env python3
"""Fetch pinned external sources into sources/cache and verify SHA-256."""
import hashlib, json, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REGISTRY = json.loads((ROOT / 'sources/sources.json').read_text())

def fetch(url, dest):
    dest.parent.mkdir(parents=True, exist_ok=True)
    if 'web.archive.org' in url:
        cmd = ['curl', '--compressed', '-L', '--retry', '4', '--retry-delay', '2', '--max-time', '60', '-s', '-A', 'Mozilla/5.0', url, '-o', str(dest)]
    else:
        cmd = ['curl', '-L', '--retry', '4', '--retry-delay', '2', '--max-time', '60', '-s', url, '-o', str(dest)]
    subprocess.run(cmd, check=True)

def verify(path, expected):
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    if actual != expected:
        raise SystemExit(f'hash mismatch for {path}: {actual} != {expected}')
    return actual

for s in REGISTRY['sources']:
    if 'fetchUrl' in s:
        dest = ROOT / s.get('cachePath', s['file'])
        if dest.exists():
            try:
                verify(dest, s['sha256'])
                print('OK cached', s['id'])
                continue
            except SystemExit:
                pass
        fetch(s['fetchUrl'], dest)
        verify(dest, s['sha256'])
        print('OK', s['id'])
    elif 'manifest' in s:
        manifest = json.loads((ROOT / s['manifest']).read_text())
        verify(ROOT / s['manifest'], s['manifestSha256'])
        for page in manifest['pages']:
            dest = ROOT / page.get('cachePath', page['html'])
            if dest.exists():
                try:
                    verify(dest, page['sha256'])
                    continue
                except SystemExit:
                    pass
            fetch(page['archiveUrl'], dest)
            verify(dest, page['sha256'])
        print('OK cached', s['id'], len(manifest['pages']), 'pages')
    elif 'file' in s:
        verify(ROOT / s['file'], s['sha256'])
        print('OK', s['id'])
print('All pinned sources fetched and verified.')
