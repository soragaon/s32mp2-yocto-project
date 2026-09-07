require recipes-st/images/st-image-core.bb
SUMMARY = "STM32MP257F-DK console-only SD card image"
DESCRIPTION = "OpenSTLinux core with networking and Dropbear SSH, without a graphical desktop."
IMAGE_FEATURES:remove = "splash x11-base x11-sato weston"
# Development board: serial root login is initially passwordless. SSH empty
# passwords are not enabled; set a password over the serial console first.
IMAGE_FEATURES += "empty-root-password allow-root-login"
IMAGE_FEATURES:remove = "debug-tweaks"
SYSTEMD_DEFAULT_TARGET = "multi-user.target"

# Fail image construction if a desktop server enters the root filesystem.
python headless_check_manifest() {
    import os
    manifest = d.getVar('IMAGE_MANIFEST')
    if not os.path.isfile(manifest):
        bb.fatal('Image package manifest missing: %s' % manifest)
    forbidden = ('weston', 'xserver-xorg', 'xwayland', 'gnome-shell', 'xfce4-session')
    with open(manifest) as stream:
        found = [line.split()[0] for line in stream if line.strip()
                 and any(line.split()[0] == p or line.split()[0].startswith(p + '-') for p in forbidden)]
    if found:
        bb.fatal('GUI packages found in headless image: %s' % ', '.join(found))
}
IMAGE_POSTPROCESS_COMMAND:append = " headless_check_manifest;"
