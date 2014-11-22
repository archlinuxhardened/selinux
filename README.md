PKGBUILDs for SELinux support in Arch Linux
===========================================

Complete documentation will soon be available at:
https://wiki.archlinux.org/index.php/SELinux

Authors
-------

Authors are credited in the PKGBUILD file for each package.

Binary repository
-----------------

A repository with built and signed packages for x86-64 only is available at
http://repo.siosm.fr/siosm-selinux/ (See https://tim.siosm.fr/repositories/ if
you need help / instructions).

Build order
-----------

Remember to build as a non-root user, and to keep a root logged-in console to
install packages (especially for sudo/shadow/pam packages).

* linux-selinux (support in Arch Official kernel on the way:
  https://bugs.archlinux.org/task/37578) can be built at any time.

First, we build all packages from the SELinux userspace projet. They do not
replace any official Arch Linux packages:

* libsepol
* libselinux
* checkpolicy setools
* libcgroup libsemanage sepolgen
* policycoreutils

Now we start replacing core packages:

* pambase-selinux
* pam-selinux
* coreutils-selinux shadow-selinux cronie-selinux sudo-selinux
* util-linux-selinux
* systemd-selinux

Optionnal but very nice to have:
* openssh-selinux findutils-selinux psmisc-selinux

Policy
------

There is not yet a SELinux policy for Arch.  To build a policy, here are some useful links:

* https://github.com/TresysTechnology/refpolicy The Reference Policy
* https://github.com/pebenito/refpolicy ongoing work to include a systemd policy in the refpolicy (announcement: http://oss.tresys.com/pipermail/refpolicy/2014-October/007430.html)
* http://anonscm.debian.org/cgit/selinux/refpolicy.git/tree/debian/patches Debian patches for refpolicy package (including systemd patches)
* https://github.com/selinux-policy/selinux-policy/tree/rawhide-base Fedora policy
