# iMac 2011 hardware support

The `imac2011` bundle installs firmware, Intel microcode, sensor tools and system
preferences. On Arch and Omarchy, firmware comes from the native `linux-firmware`
packages, including the Radeon firmware used by the 2011 iMac. Debian repository
setup is skipped on Arch and Omarchy.

`mbpfan` installs only on `iMac12,2`. Debian uses its native package. Arch and
Omarchy build a pacman package from upstream mbpfan 2.4.0, pinned to Git commit
`a9c324db67470a222b20d8ddaa9b4e1e488e9771`. The manifest declares the build tools;
no AUR helper is required. Building runs as the regular user; only package
installation, module loading and service activation require sudo.

Installation loads `applesmc` and `coretemp`, then enables and starts
`mbpfan.service`. The package installs persistent module-loading configuration.
Uninstall stops the service before removing the package. Pacman preserves edited
`/etc/mbpfan.conf` using its normal backup policy.

Reboot after firmware, microcode or Apple keyboard driver updates. This bundle
does not change GPU drivers, boot parameters, monitor layouts or the desktop
session. Hardware operation still depends on the installed kernel and GPU's
support for the chosen compositor.

The Arch build includes a patch for kernels exposing applesmc fans through
`hwmon/hwmon*/fan*_target` and `pwm*_enable`. It discovers the hwmon index at
runtime and restores automatic control with mode 2 on that interface. Package
revision 2 rebuilds an installed revision 1. Build-time tests exercise all three
fans, minimum/maximum readings, speed writes and return to automatic control on
both supported kernel interfaces, using temporary files rather than hardware.
