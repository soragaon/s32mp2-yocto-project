#!/usr/bin/env bash
# Install Ubuntu host tools; optionally fetch, configure and build pinned sources.
set -euo pipefail
usage() {
    echo 'Usage: bash scripts/setup.sh [--deps-only | --build] [--work DIR]'
    echo 'Default: install dependencies, fetch pinned sources and configure (no build).'
}
work="$HOME/stm32mp257-yocto"
mode=configure
while (( $# )); do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --deps-only) mode=deps ;;
        --build) mode=build ;;
        --work) [[ $# -ge 2 && -n "$2" ]] || { usage >&2; exit 2; }; work=$2; shift ;;
        *) usage >&2; exit 2 ;;
    esac
    shift
done
if (( EUID == 0 )); then
    echo 'Run as your normal Ubuntu user; the script uses sudo for packages only.' >&2
    exit 1
fi
source /etc/os-release
if [[ "$ID" != ubuntu || "$VERSION_ID" != 22.04 ]]; then
    echo 'This installer targets Ubuntu 22.04 (native Linux or WSL 2).' >&2
    exit 1
fi
project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if [[ "$mode" != deps ]]; then
    mkdir -p -- "$work"
    work=$(realpath -- "$work")
    case "$(stat -f -c %T "$work")" in
        9p|v9fs|ntfs*|drvfs|fuseblk)
            echo 'Choose a Linux filesystem work directory, for example ~/stm32mp257-yocto.' >&2
            exit 1 ;;
    esac
fi
sudo apt-get update
sudo apt-get install -y build-essential chrpath cpio debianutils diffstat file \
    gawk gcc git iputils-ping libacl1 liblz4-tool locales python3 python3-git \
    python3-jinja2 python3-pexpect python3-pip python3-subunit socat texinfo \
    unzip wget xz-utils zstd bzip2 bc bison flex libssl-dev rsync curl \
    rpcsvc-proto patch perl tar util-linux ca-certificates
sudo locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
[[ "$mode" != deps ]] || { echo 'Host dependencies installed.'; exit 0; }
bash "$project/scripts/check-host.sh" "$work"
python3 "$project/scripts/fetch-sources.py" "$work/sources"
python3 "$project/scripts/configure.py" "$work"
if [[ "$mode" == build ]]; then
    bash "$project/scripts/build.sh" "$work"
else
    printf 'Setup complete. Build with: bash %q %q\n' "$project/scripts/build.sh" "$work"
fi
