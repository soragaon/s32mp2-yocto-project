# Headless STM32MP257 Yocto Image

`st-image-headless.bb` defines the console-only SD card image for the
STM32MP257F-DK (`stm32mp25-disco` Yocto machine). It extends ST's
`st-image-core` image and configures a `multi-user.target` system without
Weston, X11, or other desktop services.

The recipe keeps serial root login available for initial board setup. Set a
root password from the serial console before using SSH.

## Build

Run the project build wrapper from the repository root. Build sources, the
download cache, sstate cache, and build directory must be on a native Linux
filesystem; do not use the mounted Windows workspace for those directories.

```bash
cd /mnt/e/stm32mp2
WORK="$HOME/stm32mp257-yocto"

python3 scripts/fetch-sources.py "$WORK/sources"
python3 scripts/configure.py "$WORK"
scripts/check-host.sh "$WORK"
scripts/build.sh "$WORK"
```

The wrapper runs:

```bash
bitbake st-image-headless
```

## Output

On success, `scripts/collect-image.sh` copies the compressed SD-card image,
block map when available, and checksum to the repository's `artifacts/`
directory:

```text
artifacts/stm32mp257f-dk-headless.wic.bz2
artifacts/stm32mp257f-dk-headless.wic.bmap
artifacts/SHA256SUMS
```

The complete BitBake deployment output remains in:

```text
$WORK/build/tmp*/deploy/images/stm32mp25-disco/
```

For host setup, SD-card flashing, and board validation instructions, see the
[project README](../../../README.md).