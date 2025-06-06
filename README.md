![build](https://github.com/archlinuxhardened/selinux/workflows/Build/badge.svg)

PKGBUILDs for SELinux support in Arch Linux
===========================================

Complete documentation will soon be available at:
https://wiki.archlinux.org/index.php/SELinux

Authors
-------

Authors are credited in the PKGBUILD file for each package.

Binary repository
-----------------

The releases page functions as a pacman repository. It can also be used when
installing Arch Linux using `base-selinux` -package instead of plain `base`.

To use it, add the following lines to your `/etc/pacman.conf`:
```
[selinux]
Server = https://github.com/archlinuxhardened/selinux/releases/download/ArchLinux-SELinux
SigLevel = Never
```
While the repository remains unsigned, SigLevel has to be set to Never.

Build order
-----------

Remember to build as a non-root user, and to keep a root logged-in console to
install packages (especially for sudo/shadow/pam packages).

First, we build all packages from the SELinux userspace project. They do not
replace any official Arch Linux packages:

* libsepol
* libselinux
* secilc
* checkpolicy
* setools
* libsemanage
* semodule-utils
* policycoreutils
* selinux-dbus-config
* selinux-gui
* selinux-python
* selinux-sandbox
* mcstrans
* restorecond

This makes it possible to install a pacman hook which relabels files when installing and updating packages:
* selinux-alpm-hook

Now we start replacing core packages:

* pambase-selinux
* pam-selinux
* coreutils-selinux shadow-selinux cronie-selinux sudo-selinux
* util-linux-selinux
* systemd-selinux
* logrotate-selinux
* dbus-selinux

Optional but very nice to have:
* openssh-selinux findutils-selinux iproute2-selinux psmisc-selinux

Policy
------

There is not yet a SELinux policy for Arch.  To build a policy, here are some useful links:

* https://github.com/SELinuxProject/refpolicy The Reference Policy
* https://github.com/pebenito/refpolicy ongoing work to include a systemd policy in the refpolicy (announcement: http://oss.tresys.com/pipermail/refpolicy/2014-October/007430.html)
* http://anonscm.debian.org/cgit/selinux/refpolicy.git/tree/debian/patches Debian patches for refpolicy package (including systemd patches)
* https://github.com/selinux-policy/selinux-policy/tree/rawhide-base Fedora policy
