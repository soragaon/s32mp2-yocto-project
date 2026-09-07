# STM32MP257F-DK headless Yocto project

Status: the recorded build completed all 7,116 tasks successfully (8 warnings).
A compressed SD image and block map are present locally. Hardware boot has not
been validated. Generated images and logs are excluded from Git.
See [docs/WORK_LOG.md](docs/WORK_LOG.md) for execution results.

This project pins ST OpenSTLinux 6.2.1 / Yocto Scarthgap / Linux 6.6 using
`openstlinux-6.6-yocto-scarthgap-mpu-v26.06.10`.
The board is `stm32mp257f-dk`; its Yocto MACHINE is `stm32mp25-disco`.
Boot uses TF-A, OP-TEE and U-Boot. The image is `st-image-headless`, derived from
ST's `st-image-core`. The custom distribution removes graphical features.

For a clean build entirely in your Ubuntu home directory, see
[the Ubuntu build guide](README-UBUNTU.md), including dependencies and exactly
which files to copy. It also lists [direct BitBake image commands](README-UBUNTU.md#7-direct-bitbake-commands-headless-minimal-and-graphical-images)
for headless, minimal and Weston builds.

## Quick start and WSL 2 setup

Repository name: `s32mp2-yocto-project`.
This is an STM32MP2 **Yocto** project.

For a new Windows host, open PowerShell as Administrator:

```powershell
wsl --install -d Ubuntu-22.04
# Restart if requested, then complete Ubuntu's normal-user account setup.
wsl --list --verbose
# If the installed distribution shows version 1:
wsl --set-version Ubuntu-22.04 2
```

The previous build ran on Ubuntu 22.04 under WSL 2 with about 15 GiB RAM
and 4 GiB swap, using the non-root account `akash1`. Project files were on
`/mnt/e/stm32mp2`, while compilation and caches were on Linux storage at
`/tmp/stm32mp257-yocto`. These are recorded session choices, not account or
Windows settings automatically changed by this repository. Use a persistent
home directory for new builds because `/tmp` may be cleared.

In an Ubuntu terminal, after the repository has been published:

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/soragaon/s32mp2-yocto-project.git
cd s32mp2-yocto-project
bash scripts/setup.sh
# Start compilation after setup, or use setup.sh --build for both:
bash scripts/build.sh "$HOME/stm32mp257-yocto"
```

For the existing workspace, run `bash scripts/setup.sh` from `/mnt/e/stm32mp2`.
The starter installs the Ubuntu host dependencies (including `rpcgen` through
`rpcsvc-proto`), generates `en_US.UTF-8`, checks the host, fetches the pinned
layers and creates the configuration. It uses sudo only for host installation;
run it as a normal user. Network access and sudo privileges are required.
It does not install Windows/WSL itself or accept ST's optional EULA.

```bash
bash scripts/setup.sh --deps-only
bash scripts/setup.sh --work "$HOME/stm32mp257-yocto" --build
bash scripts/setup.sh --help
```

Rerunning setup preserves edited build configuration and stops if it differs
from the project template. Review differences before updating an existing
`build/conf/local.conf` or `bblayers.conf`.

See [Microsoft's WSL installation instructions](https://learn.microsoft.com/en-us/windows/wsl/install)
and [Yocto Scarthgap host requirements](https://docs.yoctoproject.org/5.0.12/ref-manual/system-requirements.html).
Yocto permits WSL 2 use but does not validate it as a build host.

## Files

- `scripts/setup.sh`: host dependency installer and optional end-to-end starter.
- `docs/PATCHES.md`: complete inventory of local customizations and fixes.
- `upstream-manifest/default.xml`: official pinned source revisions.
- `meta-headless/`: custom distribution and image recipe.
- `conf/local.conf`: SD card, build resource and image settings.
- `scripts/fetch-sources.py`: exact-commit downloads via HTTPS GitHub mirrors.
- `scripts/configure.py`: generate build configuration, preserving edited files.
- `scripts/build.sh`: build, log output and collect compressed WIC image.
- `scripts/collect-image.sh`: collect a completed image and SHA-256 checksum.
- `docs/WORK_LOG.md`: decisions, validation and current blockers.

## Host and build

Use Ubuntu 22.04 with a normal user and a native Linux filesystem (ext4).
Keep the project on E: if desired, but put sources, build, downloads and sstate on
Linux storage. Do not build as root or disable Yocto's root sanity check.
Allow several hours for a first build and substantial disk space; 150 GB free is
a practical starting allocation, not a measured requirement for this project.
The configuration limits parallel compilation to four tasks / four make jobs.

Install host prerequisites from a normal Ubuntu user's terminal:

```bash
bash scripts/setup.sh --deps-only
```

Build from a normal user's terminal (no GUI needed):

```bash
cd /mnt/e/stm32mp2
# Choose persistent Linux storage. /tmp can be cleaned at reboot.
WORK="$HOME/stm32mp257-yocto"
mkdir -p "$WORK"
python3 scripts/fetch-sources.py "$WORK/sources"
python3 scripts/configure.py "$WORK"
scripts/check-host.sh "$WORK"
scripts/build.sh "$WORK"
```

To run BitBake directly after the configuration has been created:

```bash
# Run as the non-root user that owns the work directory.
export WORK=/tmp/stm32mp257-yocto
source "$WORK/sources/layers/openembedded-core/oe-init-build-env" "$WORK/build"
bitbake st-image-headless
```

The `source` command changes the current directory to `$WORK/build`. Run it only
once per shell; to start a new shell, use the same absolute-path command again.

This session uses `/tmp/stm32mp257-yocto` as Linux build storage, owned by the
existing user `akash1`. To resume that build, use the same scripts with that path.
Source layers remain unmodified. ST's meta-gnome and meta-multimedia are present
because its distribution layer declares dependencies on them; their presence
does not install a desktop. A post-image package check rejects desktop servers.

The project sets `ACCEPT_EULA_stm32mp25-disco = "0"` and does not claim acceptance
of ST's optional binary EULA. Component licenses remain applicable. If a needed
recipe requires explicit acceptance, review its license before changing this.

## Outputs and SD card

After a successful build:

- `artifacts/stm32mp257f-dk-headless.wic.bz2`: compressed, partitioned SD image.
- `artifacts/stm32mp257f-dk-headless.wic.bmap`: block map, when produced.
- `artifacts/SHA256SUMS`: image checksum.
- `logs/build.log`: latest build output.
- Full BSP output: `$WORK/build/tmp*/deploy/images/stm32mp25-disco/`.

The ST WIC layout includes redundant first-stage bootloaders, metadata, FIP,
U-Boot environment, bootfs, rootfs and userfs. It is a whole-card image; a rootfs
archive alone is not sufficient to boot this board.

Use an SD card large enough for the decompressed image (8 GB or larger suggested).
Identify the entire removable card carefully with `lsblk`. Writing the image
erases the selected card. Replace `/dev/sdX` below with the actual card, not a
partition or your system disk. Unmount its mounted partitions first.

```bash
cd /mnt/e/stm32mp2/artifacts
sha256sum -c SHA256SUMS
bunzip2 -k stm32mp257f-dk-headless.wic.bz2
lsblk -o NAME,SIZE,MODEL,TRAN,MOUNTPOINTS
sudo dd if=stm32mp257f-dk-headless.wic of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

Power the board off, insert the SD card, select SD boot according to the board
manual, connect the ST-LINK virtual serial port, and power on. Use 115200 baud,
8 data bits, no parity, one stop bit, no flow control. Use the serial console for
initial login and set a root password with `passwd`. Connect Ethernet and use
`ip addr` to find the address, then `ssh root@BOARD_IP`.

On the board verify `uname -a`, `cat /etc/os-release`, `findmnt /`, and
`systemctl get-default` (expected `multi-user.target`). Confirm no Weston or X
server is running. Hardware boot validation requires the actual board and card.

## References

- [ST manifest, selected release](https://github.com/STMicroelectronics/oe-manifest/tree/openstlinux-6.6-yocto-scarthgap-mpu-v26.06.10)
- [ST board machine configuration](https://github.com/STMicroelectronics/meta-st-stm32mp/blob/49046b2a0ad4dc29117025c94838b9befff86f23/conf/machine/stm32mp25-disco.conf)
- [ST SD card population guide](https://wiki.st.com/stm32mpu/wiki/How_to_populate_the_SD_card_with_dd_command)
- [STM32MP257F-DK product and board documentation](https://www.st.com/en/evaluation-tools/stm32mp257f-dk.html)

To view the latest task or failure from another terminal:

```bash
/mnt/e/stm32mp2/scripts/status.sh
# Live output:
tail -f /mnt/e/stm32mp2/logs/build.log
```

After an interrupted or failed build, run `scripts/build.sh "$WORK"` again.
BitBake reuses completed tasks and cached downloads. Do not run two builds in
the same work directory simultaneously.
