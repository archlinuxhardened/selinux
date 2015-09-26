#!/bin/sh

# Build in yaourt temporary folder by default.
# This directory can be specifically mounted with "exec" option on systems
# where /tmp is mounted "noexec".
BUILDDIR="${BUILDDIR:-/tmp/yaourt-tmp-$(id -nu)}"
export BUILDDIR

# Build a package
pkgbuild() {
    # Clean up the package folder
    rm -rf "./$1/src" "./$1/pkg"
    rm -f "./$1/"*.pkg.tar.xz "./$1/"*.pkg.tar.xz.sig

    # makepkg options:
    # -s (--syncdeps): Install missing dependencies
    # -C (--cleanbuild): Remove $srcdir before building the package
    (cd "./$1" && makepkg -s -C) || exit $?

    # Uncomment to install non-debug packages
    #sudo pacman -U $(ls *.pkg.tar.xz | grep -v "\-debug") || exit $?
}

# Build SELinux userspace packages
pkgbuild libsepol
pkgbuild libselinux
pkgbuild checkpolicy
pkgbuild setools
pkgbuild libsemanage
pkgbuild sepolgen
pkgbuild policycoreutils

# Build core packages with SELinux support
pkgbuild pambase-selinux
pkgbuild pam-selinux
pkgbuild coreutils-selinux
pkgbuild findutils-selinux
pkgbuild iproute2-selinux
pkgbuild logrotate-selinux
pkgbuild openssh-selinux
pkgbuild psmisc-selinux
pkgbuild shadow-selinux
pkgbuild sudo-selinux
pkgbuild util-linux-selinux
pkgbuild systemd-selinux
pkgbuild dbus-selinux
pkgbuild cronie-selinux

# Build refpolicy source package
pkgbuild selinux-refpolicy-src

# Finally build the kernel
pkgbuild linux-selinux
