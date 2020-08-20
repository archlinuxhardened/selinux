#!/bin/bash
# Build clean packages using "makecleanpkg" (non-root makechrootpkg, with proot)
# https://github.com/fishilico/home-files/blob/master/bin/makecleanpkg
set -e

cd "$(dirname -- "$0")"

# All dependencies that have been built, pkgname => path to package
declare -A PKGDEPS

# Build a package
#  $1: package name
#  $2...: local dependencies
pkgbuild() {
    local pkg pkgfiles have_all_files curfile cmdline

    # Grab the package name
    pkg="$1"
    shift

    # Find all packages which are built
    # shellcheck disable=SC1090,SC1091 # shellcheck complains about "source"
    mapfile -t pkgfiles < <( \
        shopt -u extglob ; \
        declare -a pkgname ; \
        arch= ; \
        pkgver= ; \
        pkgrel= ; \
        CARCH= ; \
        source /etc/makepkg.conf ; \
        source "$pkg/PKGBUILD" ; \
        if [ "$arch" = any ] ; then \
            CARCH=any ; \
        fi ; \
        for curname in "${pkgname[@]}" ; do \
            echo "$curname=$pkg/$curname-$pkgver-$pkgrel-$CARCH$PKGEXT" ; \
        done)

    # Fill PKGDEPS array
    have_all_files=true
    for curfile in "${pkgfiles[@]}"
    do
        PKGDEPS[${curfile%%=*}]="${curfile#*=}"
        if ! [ -r "${curfile#*=}" ]
        then
            have_all_files=false
        fi
    done

    # Do not rebuild if all the packages have already been built
    if "$have_all_files"
    then
        echo "$pkg has already been built"
        return
    fi

    # Find dependencies
    cmdline=(makecleanpkg)
    while [ $# -ge 1 ]
    do
        cmdline+=(-I "../${PKGDEPS[$1]}")
        shift
    done

    echo "Building $pkg: ${cmdline[*]}"
    if ! (cd "$pkg" && "${cmdline[@]}")
    then
        echo >&2 "Error: unable to build $pkg"
        return 1
    fi

    # Check all files
    have_all_files=true
    for curfile in "${pkgfiles[@]}"
    do
        if ! [ -r "${curfile#*=}" ]
        then
            echo >&2 "Error: package ${curfile%%=*} has not been built (${curfile#*=})"
            have_all_files=false
        fi
    done
    if "$have_all_files"
    then
        return 0
    fi
    return 1
}

# Build SELinux userspace packages
pkgbuild libsepol
pkgbuild libselinux libsepol
pkgbuild checkpolicy libsepol libselinux
pkgbuild secilc libsepol libselinux checkpolicy
pkgbuild setools libsepol libselinux checkpolicy
pkgbuild libsemanage libsepol libselinux
pkgbuild sepolgen libsepol libselinux # old package (<2.7)
pkgbuild semodule-utils libsepol

pkgbuild restorecond libsepol libselinux
pkgbuild mcstrans libsepol libselinux
pkgbuild policycoreutils libsepol libselinux libsemanage
pkgbuild selinux-python libsepol libselinux libsemanage setools python-ipy
pkgbuild selinux-gui libsepol libselinux libsemanage setools python-ipy selinux-python
pkgbuild selinux-dbus-config libsepol libselinux libsemanage setools python-ipy selinux-python
pkgbuild selinux-sandbox libsepol libselinux libsemanage setools python-ipy selinux-python

# Build pacman hook
pkgbuild selinux-alpm-hook libsepol libselinux libsemanage policycoreutils

# Build refpolicy source package and Arch Linux policy
pkgbuild selinux-refpolicy-src libsepol libselinux libsemanage checkpolicy policycoreutils
pkgbuild selinux-refpolicy-arch libsepol libselinux libsemanage semodule-utils checkpolicy policycoreutils
pkgbuild selinux-refpolicy-git libsepol libselinux libsemanage semodule-utils checkpolicy policycoreutils

# Build core packages with SELinux support
pkgbuild pam-selinux libsepol libselinux
pkgbuild pambase-selinux pam-selinux
pkgbuild coreutils-selinux libsepol libselinux
pkgbuild findutils-selinux libsepol libselinux
pkgbuild iproute2-selinux libsepol libselinux
pkgbuild logrotate-selinux libsepol libselinux
pkgbuild openssh-selinux libsepol libselinux
pkgbuild psmisc-selinux libsepol libselinux
pkgbuild shadow-selinux libsepol libselinux libsemanage pambase-selinux pam-selinux
pkgbuild sudo-selinux libsepol libselinux pambase-selinux pam-selinux
pkgbuild util-linux-selinux libsepol libselinux pambase-selinux pam-selinux
# FIXME: proot issue with systemd:
#     Build targets in project: 1396
#     ninja: Entering directory `build'
#     proot warning: ptrace(POKEDATA): Input/output error
#     [1/1822] Generating systemd.be@latin.catalog with a meson_exe.py custom command.
#     FAILED: catalog/systemd.be@latin.catalog
#     /usr/bin/python /usr/bin/meson --internal exe /build/systemd-selinux/src/build/meson-private/meson_exe_sed_d1ecc9b4b7c4b53a60575e96984510555baef4ca.dat
#     [2/1822] Generating systemd.zh_TW.catalog with a meson_exe.py custom command.
#     [3/1822] Generating systemd.be.catalog with a meson_exe.py custom command.
#     FAILED: catalog/systemd.be.catalog
#     /usr/bin/python /usr/bin/meson --internal exe /build/systemd-selinux/src/build/meson-private/meson_exe_sed_28432df3eb55010b242c7b86944416370642676d.dat
#pkgbuild systemd-selinux libsepol libselinux libsemanage pambase-selinux pam-selinux shadow-selinux
#pkgbuild dbus-selinux libsepol libselinux systemd-libs-selinux systemd-selinux
pkgbuild cronie-selinux libsepol libselinux pambase-selinux pam-selinux

# Finally build the kernel
pkgbuild linux-selinux
