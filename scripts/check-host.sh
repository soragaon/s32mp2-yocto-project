#!/usr/bin/env bash
set -euo pipefail
work=${1:-/tmp/stm32mp257-yocto}
failed=0
if (( EUID == 0 )); then echo 'FAIL: run the build as a non-root user'; failed=1; fi
for tool in git python3 gcc g++ make chrpath cpio gawk diffstat wget unzip xz zstd lz4 bzip2 patch perl tar file rpcgen; do
    if ! command -v "$tool" >/dev/null; then echo "FAIL: missing $tool"; failed=1; fi
done
if ! locale -a | grep -qi '^en_US\.utf'; then echo 'FAIL: en_US.UTF-8 locale missing'; failed=1; fi
if [[ -d "$work" ]]; then
    fs=$(stat -f -c %T "$work")
    case "$fs" in 9p|v9fs|ntfs*|drvfs) echo "FAIL: use native Linux storage, current type: $fs"; failed=1;; esac
    df -h "$work"
else
    echo "Create a native Linux work directory: $work"
fi
exit "$failed"
