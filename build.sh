#!/bin/sh

# Build in a per-user temporary folder by default, if there is no directory
# specified in /etc/makepkg.conf.
# This directory can be specifically mounted with "exec" option on systems
# where /tmp is mounted "noexec".

# Find the configured BUILDDIR
if [ -z "$BUILDDIR" ] ; then
    BUILDDIR="$(bash -c 'shopt -u extglob ; source /etc/makepkg.conf ; echo $BUILDDIR')"
    if [ -z "$BUILDDIR" ] ; then
        BUILDDIR="/tmp/makepkg-$(id -nu)"
    fi
fi
export BUILDDIR

# Build a package
pkgbuild() {
    # Uncomment the following line to skip already-installed packages
    #if pacman -Qq "$1" > /dev/null 2>&1 ; then return; fi

    # Clean up the package folder
    rm -rf "./$1/src" "./$1/pkg"
    rm -f "./$1/"*.pkg.tar.xz "./$1/"*.pkg.tar.xz.sig

    # makepkg options:
    # -s (--syncdeps): Install missing dependencies
    # -C (--cleanbuild): Remove $srcdir before building the package
    (cd "./$1" && makepkg -s -C) || exit $?

    # Uncomment the following line to install or update the non-debug packages
    #sudo pacman -U $(ls "./$1/"*.pkg.tar.xz | grep -vE '[-]debug') || exit $?
}

# Build SELinux userspace packages
pkgbuild libsepol
pkgbuild libselinux
pkgbuild secilc
pkgbuild checkpolicy
pkgbuild setools3-libs
pkgbuild setools
pkgbuild ustr-selinux
pkgbuild libsemanage
pkgbuild sepolgen

# policycoreutils depends on pam-selinux
pkgbuild pambase-selinux
pkgbuild pam-selinux
pkgbuild policycoreutils

# Build core packages with SELinux support
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

# Build refpolicy source package and Arch Linux policy and pacman hook
pkgbuild selinux-refpolicy-src
pkgbuild selinux-refpolicy-arch
pkgbuild selinux-alpm-hook

# Finally build the kernel
pkgbuild linux-selinux
