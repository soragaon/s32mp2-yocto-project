#!/usr/bin/env python3
"""Fetch exact commits from the vendored ST manifest using HTTPS mirrors."""
import pathlib
import subprocess
import sys
import xml.etree.ElementTree as ET

project = pathlib.Path(__file__).resolve().parents[1]
dest = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else project / 'sources'
manifest = ET.parse(project / 'upstream-manifest/default.xml').getroot()
mirrors = {'bitbake': 'https://github.com/openembedded/bitbake.git',
           'openembedded-core': 'https://github.com/openembedded/openembedded-core.git',
           'meta-openembedded': 'https://github.com/openembedded/meta-openembedded.git'}
for entry in sorted(manifest.findall('project'), key=lambda e: len(e.attrib['path'])):
    name, rev = entry.attrib['name'], entry.attrib['revision']
    path = dest / entry.attrib['path']
    url = mirrors.get(name, f'https://github.com/STMicroelectronics/{name}.git')
    if not (path / '.git').exists():
        path.mkdir(parents=True, exist_ok=True)
        subprocess.run(['git', 'init', str(path)], check=True)
        subprocess.run(['git', '-C', str(path), 'remote', 'add', 'origin', url], check=True)
    head = subprocess.run(['git', '-C', str(path), 'rev-parse', 'HEAD'], capture_output=True, text=True)
    if head.stdout.strip() == rev:
        continue
    subprocess.run(['git', '-C', str(path), 'fetch', '--depth=1', 'origin', rev], check=True)
    subprocess.run(['git', '-C', str(path), 'checkout', '--detach', rev], check=True)
print(f'Sources ready: {dest}')
