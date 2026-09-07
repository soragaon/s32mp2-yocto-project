# Local patches and configuration changes

All seven upstream source repositories have no tracked modifications as checked
on 2026-09-07. There are no standalone `.patch` files or kernel/U-Boot source
patches in this project. The changes are a custom Yocto layer, configuration and
host scripts; a fresh setup applies them by adding the layer to `BBLAYERS`.

| File | Change and reason |
| --- | --- |
| `meta-headless/conf/layer.conf` | Registers the Scarthgap-compatible custom layer. |
| `meta-headless/conf/distro/stm32mp-headless.conf` | Extends ST's distro, removing desktop and GPU-related features. |
| `meta-headless/recipes-core/images/st-image-headless.bb` | Extends `st-image-core`, sets `multi-user.target`, permits initial serial root setup and rejects desktop servers in the image package manifest. Empty-password SSH is not enabled. |
| `conf/local.conf` | Selects STM32MP25 Discovery, OP-TEE, SD boot, ST's WIC layout, bootfs/userfs and compressed image output. Limits builds to four tasks/four make jobs, sets disk thresholds, caches and `rm_work`; leaves optional EULA acceptance off. |
| `conf/local.conf` connectivity setting | Uses GitHub HTTPS instead of the failing default example.com probe while retaining network sanity checks. |
| `scripts/fetch-sources.py` | Fetches seven exact manifest commits using GitHub HTTPS mirrors for OpenEmbedded. |
| `scripts/configure.py` | Registers required ST/OpenEmbedded layers and the custom layer; refuses to overwrite edited configuration. GNOME/multimedia layers satisfy metadata dependencies without installing a desktop. |
| `scripts/check-host.sh` | Checks non-root execution, tools, locale and build filesystem. |
| `scripts/build.sh` | Runs BitBake as a normal user, logs output and collects artifacts after success. |
| `scripts/collect-image.sh` | Matches ST filenames containing the distro name; copies the current WIC archive/block map and produces SHA-256 checksums. |
| `scripts/status.sh` | Shows collected artifacts and the latest build output. |
| `scripts/setup.sh` | Installs Ubuntu 22.04 dependencies, generates the locale, checks Linux storage, fetches/configures sources and optionally builds. |

## WSL fixes applied in the recorded session

Compilation was moved off the Windows-mounted project drive to Linux storage.
The existing user `akash1` owned the work directory and ran BitBake; root sanity
checks were retained. The connectivity probe and ST artifact filename matching
were fixed as described above. No Windows kernel, WSL networking, `.wslconfig`,
or upstream BSP source patches are recorded in this workspace.

## Build evidence and remaining validation

The retained build log ends with all 7,116 tasks successful. Its eight warnings
are one WSL VHDX storage advisory, one systemd `/home/root` advisory and six
M33 missing secure firmware folder warnings. They were not fixed by this work.
The Linux SD image build succeeded; this does not establish M33 firmware or
physical board functionality.

The local compressed image is 110,074,559 bytes. Its verified SHA-256 is:

```text
e1d3491896a57d914a226eb15bf1fe076263d785086f1916f833022fc0fa6f91
```

Hardware boot, serial login, Ethernet and SSH still need board testing.
Generated images, build logs, caches and source checkouts are excluded from Git.
