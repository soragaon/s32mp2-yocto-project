# Work log

## 2026-09-06

- Requested: Yocto project for STM32MP257F-DK, headless Linux, bootable SD card image, documentation maintained during work.
- Workspace initially empty. Host: Ubuntu 22.04, root session, 15 GiB RAM, 4 GiB swap.
- Workspace is Windows-mounted E: with about 164 GiB free. Linux /tmp has about 938 GiB free; build work should use a native Linux filesystem.
- Sandbox DNS blocked GitHub; approved network execution successfully accessed ST's public repositories.
- Selected official manifest tag `openstlinux-6.6-yocto-scarthgap-mpu-v26.06.10`, commit `71e658b9a8cff67bef0f53a3543dad19d61380f2`.
- Build and SD image generation are not yet complete.
- Downloaded all seven exact source revisions to `/tmp/stm32mp257-yocto/sources`, using HTTPS mirrors for OpenEmbedded projects. The official manifest remains in the project.
- Confirmed board-specific machine `stm32mp25-disco`, SD-only boot, OP-TEE and upstream WIC layout directly from the pinned BSP.
- Added custom layer, headless distro/image, four-job build configuration, fetch/configure/build/collect scripts and README.
- Initial sandbox ownership change failed; approved execution assigned the Linux work directory to existing non-root user `akash1`. Started BitBake through `runuser` without disabling its root safety check.
- First BitBake attempt failed the default `www.example.com` connectivity check. Verified GitHub HTTPS works as the build user; changed `CONNECTIVITY_CHECK_URIS` to GitHub, preserving network sanity checks.
- Shell syntax and Python compilation checks passed. Image login policy allows initial empty-password serial root login, but does not enable empty-password SSH.
- After applying the connectivity change as the build-directory owner, BitBake passed host sanity and began parsing recipes.
- BitBake parsed 3,048 recipes with zero errors and resolved a 7,116-task build. Source fetch and native tool compilation started successfully; no sstate cache was available.
- Confirmed ST appends the distro name to image filenames; updated artifact collection accordingly.
- Verified all seven checked-out commits against the official XML manifest.
- Host preflight passed as user `akash1`. Build is using native Linux storage, with no optional EULA acceptance and no root-sanity bypass.
- Build passed task 1,050 of 7,116 without errors. AArch64 cross-compiler compilation progressed successfully and target library preparation began. No SD image has been generated at this stage.

## 2026-09-07 — documentation and reproducible setup

- Rechecked the retained build log: all 7,116 tasks succeeded with eight warnings.
  This supersedes the in-progress status in the earlier entries.
- Verified the local compressed SD image against `artifacts/SHA256SUMS`.
- Checked all seven upstream repositories: no tracked source modifications.
- Updated the README with WSL 2 installation, the recorded host setup, current
  build status and starter commands. Added `docs/PATCHES.md` with all local
  customizations, fixes and unresolved warnings.
- Added `scripts/setup.sh` for Ubuntu 22.04 dependency installation and optional
  fetch/configure/build, using a normal user and persistent Linux storage.
- GitHub publishing requested as `soragaon/s32mp2-yocto-project`. This session
  has no GitHub CLI, credentials or connected GitHub tool. Publication remains
  pending authentication. The workspace's root `.git` is read-only; a separate
  staging checkout is used to prepare the commit without changing that mount.
