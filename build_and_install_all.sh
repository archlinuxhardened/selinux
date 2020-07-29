#!/bin/sh
# Build and install every package which is not already installed

cd "$(dirname -- "$0")" || exit $?

if [ "$(id -u)" = 0 ]
then
    echo >&2 "makepkg does not support building as root. Please run with an other user (e.g. nobody)"
    exit 1
fi

# Gather the package extension from /etc/makepkg.conf
PKGEXT="$(bash -c 'source /etc/makepkg.conf ; echo "$PKGEXT"')"
if [ -z "$PKGEXT" ]
then
    # Use zstd compression by default
    PKGEXT='.pkg.tar.zst'
fi

# Verify whether a package needs to be installed
needs_install() {
    local CURRENT_VERSION PKGREL PKGVER

    if "$UPGRADE_GIT_PACKAGE"
    then
        # Always ugrade -git packages
        if [ "${1%-git}" != "$1" ]
        then
            return 0
        fi
    fi

    CURRENT_VERSION="$(LANG=C pacman -Q "${1##*/}" 2> /dev/null | awk '{print $2}')"
    if [ -z "$CURRENT_VERSION" ]
    then
        # The package was not installed
        return 0
    fi
    PKGVER="$(sed -n 's/^\s*pkgver = \(\S\+\)/\1/p' "$1/.SRCINFO" | head -n1)"
    PKGREL="$(sed -n 's/^\s*pkgrel = \(\S\+\)/\1/p' "$1/.SRCINFO" | head -n1)"
    if [ "$CURRENT_VERSION" = "$PKGVER-$PKGREL" ]
    then
        # The package is already installed to the same version as in the tree
        return 1
    fi

    # If the package is a git package, do not install it if the git tree
    # contains an older package
    if [ "${1%-git}" != "$1" ] && [ "$(vercmp "$CURRENT_VERSION" "$PKGVER-$PKGREL")" -ge 0 ]
    then
        return 1
    fi
    return 0
}

# Build a package
# Arguments:
# - package name
# - makepkg environment tweaks
build() {
    rm -rf "./$1/src" "./$1/pkg"
    rm -f "./$1/"*.pkg.tar.xz "./$1/"*.pkg.tar.xz.sig
    rm -f "./$1/"*.pkg.tar.zst "./$1/"*.pkg.tar.zst.sig
    (cd "./$1" && shift && makepkg -s -C --noconfirm "$@") || exit $?
}

# Run an install command for a package which may conflict with a base package
# and answer yes to ":: $PKG-selinux and $PKG are in conflict. Remove $PKG? [y/N]"
# Use undocumented pacman's --ask=4 option to do this while in --noconfirm
#
# 4 is ALPM_QUESTION_CONFLICT_PKG in https://git.archlinux.org/pacman.git/tree/lib/libalpm/alpm.h?h=v5.0.2#n602
# and --ask=... inverts the default answer of the interactive question according
# to https://git.archlinux.org/pacman.git/tree/src/pacman/callback.c?h=v5.0.2#n490
run_conflictual_install() {
    local SUBCOMMAND

    if [ "$1" = "pacman" ] ; then
        shift
        set pacman '--noconfirm' '--ask=4' "$@"
    elif [ "$1" = "sh" ] && [ "$2" = "-c" ] ; then
        # run "sh -c 'subcommand with pacman'
        SUBCOMMAND="$3"
        shift 3
        set sh '-c' "$(echo "$SUBCOMMAND" | sed 's/pacman /pacman --noconfirm --ask=4 /g')" "$@"
    else
        echo >&2 "Internal error: run_conflictual_install without pacman but '$*'"
        exit 1
    fi

    # Invoke pacman with sudo
    if ! sudo LANG=C "$@"
    then
        echo >&2 "Error: the following command failed, sudo LANG=C $*"
        exit 1
    fi
}

# Build and install a package
build_and_install() {
    needs_install "$1" || return 0
    build "$@"
    run_conflictual_install pacman -U "./$1/"*"$PKGEXT"
}

# Install libreport package from the AUR, if it is not already installed
install_libreport() {
    local MAKEPKGDIR
    if pacman -Qi libreport > /dev/null 2>&1
    then
        return 0
    fi
    MAKEPKGDIR="$(mktemp -d -p "${TMPDIR:-/tmp}" makepkg-libreport-XXXXXX)"
    git -C "$MAKEPKGDIR" clone https://aur.archlinux.org/rpm-org.git || exit $?
    (cd "$MAKEPKGDIR/rpm-org" && makepkg -si --noconfirm --asdeps) || exit $?
    git -C "$MAKEPKGDIR" clone https://aur.archlinux.org/satyr.git || exit $?
    (cd "$MAKEPKGDIR/satyr" && makepkg -si --noconfirm --asdeps) || exit $?
    git -C "$MAKEPKGDIR" clone https://aur.archlinux.org/libreport.git || exit $?
    (cd "$MAKEPKGDIR/libreport" && makepkg -si --noconfirm --asdeps) || exit $?
    rm -rf "$MAKEPKGDIR"
}

# Parse options
UPGRADE_GIT_PACKAGE=false
while getopts ":gh" OPT
do
    case "$OPT" in
        h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Build and install/upgrade every package which is not already installed"
            echo ""
            echo "Optional arguments:"
            echo "  -h      display this help and exit"
            echo "  -g      always upgrade -git packages"
            echo "          (default: upgrade only when pkgver-pkgrel changes)"
            exit
            ;;
        g)
            UPGRADE_GIT_PACKAGE=true
            ;;
    esac
done

# Install the packages which are needed for the script if they are not already installed
# base and base-devel groups are supposed to be installed
for PKG in expect git
do
    if ! pacman -Qi "$PKG" > /dev/null 2>&1
    then
        sudo pacman --noconfirm -S "$PKG" || exit $?
    fi
done

# SELinux userspace packages
build_and_install libsepol
build_and_install libselinux
build_and_install secilc
build_and_install checkpolicy
# setools 3.3.8-5 Makefile has dependencies issues when installing __init__.py for qpol
# (install command can be invoked before the destination directory is created)
build_and_install setools MAKEFLAGS="-j1"
build_and_install libsemanage
build_and_install mcstrans
build_and_install policycoreutils
build_and_install semodule-utils
build_and_install restorecond
build_and_install selinux-python
build_and_install selinux-gui
build_and_install selinux-dbus-config
build_and_install selinux-sandbox

# setoubleshoot
install_libreport
build_and_install setroubleshoot

# pacman hook
build_and_install selinux-alpm-hook

# Core packages with SELinux support
build_and_install pambase-selinux
build_and_install pam-selinux
build_and_install coreutils-selinux
build_and_install findutils-selinux
build_and_install iproute2-selinux
build_and_install logrotate-selinux
build_and_install openssh-selinux
build_and_install psmisc-selinux
build_and_install shadow-selinux
build_and_install cronie-selinux

if needs_install sudo-selinux
then
    # sudo is special because /etc/sudoers gets deleted in the process
    # If we are not careful, this is a way to be locked out of a machine
    build sudo-selinux
    if [ -e "/etc/sudoers.pacsave" ]
    then
        echo >&2 'Ugh, /etc/sudoers.pacsave exists. Aborting now before breaking the system!'
        exit 1
    fi
    run_conflictual_install sh -c \
        '{ pacman -U sudo-selinux/sudo-selinux-*'"$PKGEXT"' && if test -e /etc/sudoers.pacsave ; then mv /etc/sudoers.pacsave /etc/sudoers ; fi }'
fi

# Handle util-linux/systemd build-time cycle dependency (https://bugs.archlinux.org/task/39767)
if needs_install util-linux-selinux || needs_install systemd-selinux
then
    build util-linux-selinux
    run_conflictual_install pacman -U util-linux-selinux/libutil-linux-selinux-*"$PKGEXT"
    build systemd-selinux
    run_conflictual_install pacman -U systemd-selinux/systemd-libs-selinux-*"$PKGEXT"
    build_and_install util-linux-selinux
    build_and_install systemd-selinux
fi
build_and_install dbus-selinux

# Kernel with SELinux support
# This is no longer needed, as the official kernel has been enabling SELinux
# support since 4.18.8-arch1 (2018-09-15).
# cf. https://git.archlinux.org/svntogit/packages.git/commit/trunk?h=packages/linux&id=c46609a4b0325c363455264844091b71de01eddc
# and https://github.com/archlinuxhardened/selinux/issues/19
#build_and_install linux-selinux

# Reference policy source package
build_and_install selinux-refpolicy-src

# Refpolicy with Arch Linux patches
build_and_install selinux-refpolicy-arch

# Refpolicy git master
build_and_install selinux-refpolicy-git
