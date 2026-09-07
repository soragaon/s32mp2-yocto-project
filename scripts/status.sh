#!/usr/bin/env bash
set -euo pipefail
project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if [[ -f "$project/artifacts/SHA256SUMS" ]]; then
    echo 'An image has been collected. Verify its checksum and build date before use.'
    ls -lh "$project/artifacts/"
fi
if [[ -f "$project/logs/build.log" ]]; then
    tail -n 12 "$project/logs/build.log"
else
    echo 'No build log yet.'
fi
