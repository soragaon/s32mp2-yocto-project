#!/usr/bin/env bash
set -eo pipefail
project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work=$(realpath "${1:-$project/work}")
if (( EUID == 0 )); then
    echo 'Run as a normal Linux user: BitBake refuses root.' >&2
    exit 1
fi
export LANG=en_US.UTF-8
cd "$work/sources"
source layers/openembedded-core/oe-init-build-env "$work/build" >/dev/null
mkdir -p "$project/logs"
bitbake st-image-headless 2>&1 | tee "$project/logs/build.log"
"$project/scripts/collect-image.sh" "$work"
