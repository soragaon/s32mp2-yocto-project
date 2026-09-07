#!/usr/bin/env python3
"""Create a build directory from this project's pinned source checkout."""
import pathlib
import sys
project = pathlib.Path(__file__).resolve().parents[1]
work = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else project / 'work'
layers = work / 'sources/layers'
build = work / 'build'
paths = [layers / p for p in [
    'openembedded-core/meta', 'meta-openembedded/meta-oe',
    'meta-openembedded/meta-python', 'meta-openembedded/meta-networking',
    'meta-openembedded/meta-webserver', 'meta-openembedded/meta-gnome',
    'meta-openembedded/meta-multimedia', 'meta-st/meta-st-stm32mp',
    'meta-st/meta-st-openstlinux']]
paths.append(project / 'meta-headless')
for path in paths:
    if not (path / 'conf/layer.conf').is_file():
        sys.exit(f'Missing layer: {path}. Run fetch-sources.py first.')
(build / 'conf').mkdir(parents=True, exist_ok=True)
content = 'LCONF_VERSION = "7"\nBBPATH = "${TOPDIR}"\nBBFILES ?= ""\nBBLAYERS = "' + ' '.join(map(str, paths)) + '"\n'
for name, value in [('bblayers.conf', content), ('local.conf', (project / 'conf/local.conf').read_text())]:
    target = build / 'conf' / name
    if target.exists() and target.read_text() != value:
        sys.exit(f'Refusing to overwrite edited configuration: {target}')
    target.write_text(value)
print(build)
