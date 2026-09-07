# Build STM32MP2 Yocto on Ubuntu using Linux storage

This guide builds the STM32MP257F-DK headless SD image on Ubuntu 22.04.
Keep both the project and build files under your normal user's home directory.
No Windows drive mount is needed. These steps also work inside Ubuntu on WSL 2
when your home directory is on its Linux filesystem.

## 1. Use a normal Ubuntu account

Build as a normal user with sudo access. Do not run BitBake or `setup.sh` as root.
If your prompt is `root@akash`, switch to your existing normal account:

```bash
su - akash1
```

Replace `akash1` if your Ubuntu username is different. If you do not have a
normal account, run these commands as root once, then use that account:

```bash
adduser yoctobuild
usermod -aG sudo yoctobuild
su - yoctobuild
```

Check your account and Linux storage:

```bash
whoami
printf '%s\n' "$HOME"
stat -f -c %T "$HOME"
df -h "$HOME"
free -h
```

`whoami` must not print `root`. Use native Linux storage such as ext4; do not
place the build under `/mnt/c`, `/mnt/e` or a Windows shared filesystem.
Plan for at least 150 GB free as a practical starting allocation; actual usage
varies. The previous build used about 15 GiB RAM and 4 GiB swap. The project
limits compilation to four BitBake tasks and four make jobs.

## 2. Get the project — choose one option

### Option A: Clone from GitHub

Use this after you have pushed the project to GitHub:

```bash
sudo apt-get update
sudo apt-get install -y git ca-certificates
cd "$HOME"
git clone https://github.com/soragaon/s32mp2-yocto-project.git
cd "$HOME/s32mp2-yocto-project"
```

For a private repository, authenticate first using `gh auth login` followed by
`gh auth setup-git` (install the CLI with `sudo apt-get install -y gh`).
A “Repository not found” error means the repository may not exist yet or your
account cannot access it. You can use Option B until it is published.

### Option B: Copy only the project files

Transfer the following files from the existing project using an archive, USB,
SCP or another file-copy method. Put them in `~/s32mp2-yocto-project`:

```text
s32mp2-yocto-project/
├── README.md
├── README-UBUNTU.md
├── .gitignore
├── conf/
│   └── local.conf
├── meta-headless/              # Copy this entire custom layer
├── scripts/                    # Copy all .sh and .py files
├── docs/                       # Setup history and change inventory
└── upstream-manifest/
    ├── default.xml             # Required: pins the downloaded sources
    └── License.md
```

Do not copy `.git`, `__pycache__`, `artifacts`, `logs`, `sources`, `work`,
`downloads`, `sstate-cache`, old build directories or the large SBOM files.
The scripts download the required upstream sources themselves.

For example, on the machine containing your existing minimal project, create
an archive (first copy this guide into that project):

```bash
cd ~/s32mp2-yocto-minimal
tar --exclude=__pycache__ --exclude='*.pyc' -czf ~/s32mp2-project.tar.gz \
  README.md README-UBUNTU.md .gitignore conf meta-headless scripts docs \
  upstream-manifest/default.xml upstream-manifest/License.md
```

Transfer `s32mp2-project.tar.gz` to your normal Ubuntu user's home directory.
Then, on the build machine:

```bash
mkdir -p "$HOME/s32mp2-yocto-project"
tar -xzf "$HOME/s32mp2-project.tar.gz" -C "$HOME/s32mp2-yocto-project"
cd "$HOME/s32mp2-yocto-project"
```

## 3. Set script permissions

Run this from the project directory after cloning or copying:

```bash
chmod +x scripts/*.sh
```

This also allows the build wrapper to execute the image collection script.

## 4. Install dependencies and build

The simplest path is one command from the project directory:

```bash
bash scripts/setup.sh --build
```

The starter installs the host packages using sudo, generates the UTF-8 locale,
checks the host, downloads pinned source revisions, writes build configuration
and starts `st-image-headless`. The initial build can take several hours and
needs internet access for source downloads.

The resulting directories are:

```text
~/s32mp2-yocto-project/         Project, custom layer, logs and collected image
~/stm32mp257-yocto/sources/     Upstream source layers
~/stm32mp257-yocto/build/       BitBake configuration and build output
~/stm32mp257-yocto/downloads/   Download cache
~/stm32mp257-yocto/sstate-cache/ Shared build cache
```

Keep the project in the same location after configuration: `bblayers.conf`
contains absolute paths to its custom layer.

### Separate dependency and build steps

Use these instead of the one-command path if you want to run each stage:

```bash
cd "$HOME/s32mp2-yocto-project"
bash scripts/setup.sh --deps-only
export WORK="$HOME/stm32mp257-yocto"
mkdir -p "$WORK"
bash scripts/check-host.sh "$WORK"
python3 scripts/fetch-sources.py "$WORK/sources"
python3 scripts/configure.py "$WORK"
bash scripts/build.sh "$WORK"
```

The dependency installer runs the following package and locale commands;
there is no need to repeat these after `--deps-only`:

```bash
sudo apt-get update
sudo apt-get install -y build-essential chrpath cpio debianutils diffstat file \
  gawk gcc git iputils-ping libacl1 liblz4-tool locales python3 python3-git \
  python3-jinja2 python3-pexpect python3-pip python3-subunit socat texinfo \
  unzip wget xz-utils zstd bzip2 bc bison flex libssl-dev rsync curl \
  rpcsvc-proto patch perl tar util-linux ca-certificates
sudo locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
```

The installer targets Ubuntu 22.04. `rpcsvc-proto` supplies `rpcgen`.
See the [Yocto Scarthgap host requirements](https://docs.yoctoproject.org/5.0.12/ref-manual/system-requirements.html)
for the upstream prerequisite reference. Project-specific dependencies are
included in the commands above.

## 5. Check progress and collect the result

In a second terminal:

```bash
cd "$HOME/s32mp2-yocto-project"
bash scripts/status.sh
tail -f logs/build.log
```

Press Ctrl+C to stop following the log; this does not stop the build running
in the first terminal. After a successful build, the wrapper collects:

```text
artifacts/stm32mp257f-dk-headless.wic.bz2
artifacts/stm32mp257f-dk-headless.wic.bmap  (when generated)
artifacts/SHA256SUMS
```

Verify the image:

```bash
cd "$HOME/s32mp2-yocto-project/artifacts"
sha256sum -c SHA256SUMS
```

See [the main README](README.md#outputs-and-sd-card) for SD card flashing and
serial-console setup. The existing recorded build succeeded, but hardware boot
has not been validated; see [the change inventory](docs/PATCHES.md) for warnings.

## 6. Resume a stopped build

Run the build command again, using the same work directory:

```bash
cd "$HOME/s32mp2-yocto-project"
bash scripts/build.sh "$HOME/stm32mp257-yocto"
```

Completed tasks and cached downloads are reused. Run only one build at a time
in a work directory. Do not delete caches just to resume a build.

For a separate fresh build directory:

```bash
bash scripts/setup.sh --work "$HOME/stm32mp257-yocto-fresh" --build
```

If configuration reports “Refusing to overwrite edited configuration”, inspect
its existing files before changing them, or select a new work directory as
above. If you copied an old build from another account or machine, use a fresh
work directory so it does not retain old absolute paths or ownership.

## 7. Direct BitBake commands: headless, minimal and graphical images

“Full image” means a complete image build, including its dependencies; it does
not require a graphical desktop. Choose the target below for the contents you
want. Run commands as your normal Ubuntu user.

| Target | Contents / purpose | Configuration |
| --- | --- | --- |
| `st-image-headless` | This project's complete headless SD image, with networking, Dropbear SSH and a check rejecting desktop servers | `stm32mp-headless` (default) |
| `st-image-core` | ST's base console image with package management, SSH and ST tools; lacks the custom image's desktop-package check and login settings | Use the project's headless distro |
| `core-image-minimal` | Generic Yocto boot-oriented minimal root filesystem; no SSH requested by this recipe | Use the project's headless distro; board validation required |
| `st-image-weston` | ST's larger graphical image with Weston/Wayland, tools and demos | Separate `openstlinux-weston` build configuration |

### Complete SD image without a graphical desktop

First prepare sources/configuration if you have not already done so:

```bash
cd "$HOME/s32mp2-yocto-project"
bash scripts/setup.sh
```

Initialize the environment in each new terminal before calling BitBake.
`source` changes your current directory to the build directory:

```bash
export WORK="$HOME/stm32mp257-yocto"
source "$WORK/sources/layers/openembedded-core/oe-init-build-env" "$WORK/build"
bitbake st-image-headless
```

This is the target used by `scripts/build.sh`. It builds the full headless image,
not just the kernel. “Without graphics” here means removal of desktop and
GPU-related distro features; it does not promise removal of every kernel
display driver or framebuffer console.

Direct BitBake does not copy the image into the project's `artifacts` directory.
Collect it after a successful headless build:

```bash
bash "$HOME/s32mp2-yocto-project/scripts/collect-image.sh" "$WORK"
```

### ST base console image or generic minimal image

In a terminal initialized with the same headless environment above, choose one:

```bash
# ST base console image:
bitbake st-image-core
```

```bash
# Smaller generic Yocto image:
bitbake core-image-minimal
```

The minimal recipe installs the core boot package group plus any distribution
or machine additions. It is not a guaranteed smallest possible image. It does
not inherit this project's serial login policy or desktop-package check.
Neither alternative has been built or boot-tested in this project; do not
assume a generic minimal rootfs alone is a flashable STM32MP2 SD card image.
Check the generated WIC, boot components and board boot behavior before use.

### Graphical image with Weston/Wayland

Use a fresh terminal and a separate work directory so the existing headless
configuration remains available. Prepare it, then change its distro:

```bash
cd "$HOME/s32mp2-yocto-project"
bash scripts/setup.sh --work "$HOME/stm32mp257-yocto-weston"
export WORK="$HOME/stm32mp257-yocto-weston"
sed -i 's/^DISTRO = "stm32mp-headless"$/DISTRO = "openstlinux-weston"/' \
  "$WORK/build/conf/local.conf"
source "$WORK/sources/layers/openembedded-core/oe-init-build-env" "$WORK/build"
bitbake st-image-weston
```

Do not build `st-image-weston` with `stm32mp-headless`: the Weston recipe
requires the Wayland feature removed by the headless distro. The graphical
variant has not been validated here. Optional binary recipes may require ST
license acceptance; review the applicable license before changing
`ACCEPT_EULA_stm32mp25-disco` from its default `0`.

To resume the graphical build, open a fresh terminal, set `WORK` to the Weston
work directory, source its environment and run `bitbake st-image-weston` again.
Do not rerun the setup/configure step on this edited configuration: the
configuration script intentionally refuses to overwrite it.

### Find image output

For any target, output remains under the active work directory:

```bash
ls "$WORK"/build/tmp*/deploy/images/stm32mp25-disco/
```

The project's collection script only handles `st-image-headless`. Other targets
keep their own image filenames in the deploy directory. Only the original
headless build has recorded successful build evidence in this repository.

