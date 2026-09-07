#!/usr/bin/env bash
set -euo pipefail
project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work=$(realpath "${1:-$project/work}")
shopt -s nullglob
images=("$work"/build/tmp*/deploy/images/stm32mp25-disco/st-image-headless-stm32mp-headless-stm32mp25-disco*.wic.bz2)
# Use only symlinks to the current build, or the sole timestamped image.
selected=()
for file in "${images[@]}"; do [[ ! -L "$file" ]] || selected+=("$file"); done
if (( ${#selected[@]} == 1 )); then images=("${selected[@]}"); fi
(( ${#images[@]} == 1 )) || { echo "Expected one current image; found ${#images[@]}" >&2; exit 1; }
mkdir -p "$project/artifacts"
cp -L -- "${images[0]}" "$project/artifacts/stm32mp257f-dk-headless.wic.bz2"
bmap=${images[0]%.bz2}.bmap
[[ ! -f "$bmap" ]] || cp -L -- "$bmap" "$project/artifacts/stm32mp257f-dk-headless.wic.bmap"
cd "$project/artifacts"
sha256sum stm32mp257f-dk-headless.wic.bz2 > SHA256SUMS
