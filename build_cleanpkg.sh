#!/bin/bash
# Build clean packages using "makecleanpkg" (from makechrootpkg)
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
    pkgfiles=($( \
        shopt -u extglob ; \
        source /etc/makepkg.conf ; \
        source "$pkg/PKGBUILD" ; \
        if [ "$arch" = any ] ; then \
            CARCH=any ; \
        fi ; \
        for curname in ${pkgname[@]} ; do \
            echo "$curname=$pkg/$curname-$pkgver-$pkgrel-$CARCH$PKGEXT" ; \
        done))

    # Fill PKGDEPS array
    have_all_files=true
    for curfile in ${pkgfiles[@]}
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
    for curfile in ${pkgfiles[@]}
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

# Build python-ipy from the AUR into base-noselinux/ directory
pkgbuild_python_ipy() {
    mkdir -p base-noselinux
    if ! [ -e base-noselinux/python-ipy ] ; then
        git -C base-noselinux clone https://aur.archlinux.org/python-ipy.git
    fi
    pkgbuild base-noselinux/python-ipy
}

# Build SELinux userspace packages
pkgbuild libsepol
pkgbuild libselinux libsepol
pkgbuild secilc libsepol
pkgbuild checkpolicy libsepol libselinux
pkgbuild libsepol libselinux
pkgbuild setools libsepol libselinux checkpolicy
pkgbuild libsemanage libsepol libselinux
pkgbuild sepolgen libsepol libselinux # old package (<2.7)
pkgbuild semodule-utils libsepol

pkgbuild restorecond libsepol libselinux
pkgbuild mcstrans libsepol libselinux
pkgbuild policycoreutils libsepol libselinux libsemanage
pkgbuild_python_ipy
pkgbuild selinux-python libsepol libselinux libsemanage setools python-ipy
pkgbuild selinux-gui libsepol libselinux libsemanage setools selinux-python2
pkgbuild selinux-dbus-config libsepol libselinux libsemanage setools python-ipy selinux-python
pkgbuild selinux-sandbox libsepol libselinux libsemanage setools python-ipy selinux-python

# Build pacman hook
pkgbuild selinux-alpm-hook libsepol libselinux libsemanage policycoreutils

# Build refpolicy source package and Arch Linux policy
pkgbuild selinux-refpolicy-src libsepol libselinux libsemanage checkpolicy policycoreutils
pkgbuild selinux-refpolicy-arch libsepol libselinux libsemanage semodule-utils checkpolicy policycoreutils
pkgbuild selinux-refpolicy-git libsepol libselinux libsemanage semodule-utils checkpolicy policycoreutils

# Build core packages with SELinux support
pkgbuild pambase-selinux
# Error: pambase-selinux and pambase are in conflict. Remove pambase? [y/N]
# => need pacman patch to override conflict check
pkgbuild pam-selinux libsepol libselinux pambase-selinux
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

# Finally build the kernel
pkgbuild linux-selinux
