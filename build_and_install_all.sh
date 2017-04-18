#!/bin/sh
# Build and install every package which is not already installed

cd "$(dirname -- "$0")" || exit $?

if [ "$(id -u)" = 0 ]
then
    echo >&2 "makepkg does not support building as root. Please run with an other user (e.g. nobody)"
    exit 1
fi

# Verify whether a package needs to be installed
needs_install() {
    local CURRENT_VERSION PKGREL PKGVER
    CURRENT_VERSION="$(LANG=C pacman -Q "${1##*/}" 2> /dev/null | awk '{print $2}')"
    if [ -z "$CURRENT_VERSION" ]
    then
        # The package was not installed
        return 0
    fi
    PKGVER="$(sed -n 's/^\s*pkgver = \(\S\+\)/\1/p' "$1/.SRCINFO" | head -n1)"
    PKGREL="$(sed -n 's/^\s*pkgrel = \(\S\+\)/\1/p' "$1/.SRCINFO" | head -n1)"
    if [ "$CURRENT_VERSION" != "$PKGVER-$PKGREL" ]
    then
        # The package needs to be updated
        return 0
    fi
    # The package is already installed to the same version as in the tree
    return 1
}

# Build a package
# Arguments:
# - package name
# - makepkg environment tweaks
build() {
    rm -rf "./$1/src" "./$1/pkg"
    rm -f "./$1/"*.pkg.tar.xz "./$1/"*.pkg.tar.xz.sig
    (cd "./$1" && shift && makepkg -s -C --noconfirm "$@") || exit $?
}

# Run an install command for a package which may conflict with a base package
# and answer yes to ":: $PKG-selinux and $PKG are in conflict. Remove $PKG? [y/N]"
run_conflictual_install() {
    local ATTEMPT STATUS
    for ATTEMPT in $(seq 10)
    do
        # Do not put sudo inside the expect so that passwords are not intercepted by except
        sudo LANG=C expect <<EOF
set timeout 300
set send_slow {1 1}
spawn $(echo "$*" | sed 's/pacman -U/pacman --color never -U/')
expect {
    -re {:: [-a-z0-9]+ and [-a-z0-9]+ are in conflict( \([-a-z0-9]+\))?\. Remove [-a-z0-9]+\? \[y/N\] } { sleep .5; send y\r; exp_continue }
    {:: Proceed with installation? \[Y/n\] } { sleep .5; send y\r; exp_continue }
    timeout { send_user "Time out.\n"; exit 42 }
    eof
}
foreach {pid spawnid os_error_flag value} [wait] break
exit \$value
EOF
        STATUS=$?
        if [ "$STATUS" = 0 ]
        then
            # Return if the command succeeded
            return
        elif [ "$STATUS" -ne 42 ]
        then
            echo >&2 "expect returned an error ($STATUS) when running: $*"
            exit 1
        fi
        echo "installation timed out, retrying ($ATTEMPT)"
    done
    echo >&2 "expect kept getting timed out, aborting."
    exit 1
}

# Build and install a package
build_and_install() {
    needs_install "$1" || return 0
    build "$@"
    run_conflictual_install pacman -U "./$1/"*.pkg.tar.xz
}

# Install libcgroup package from the AUR, if it is not already installed
install_libcgroup() {
    local MAKEPKGDIR
    if pacman -Qi libcgroup > /dev/null 2>&1
    then
        return 0
    fi
    MAKEPKGDIR="$(mktemp -d makepkg-libcgroup-XXXXXX)"
    git -C "$MAKEPKGDIR" clone https://aur.archlinux.org/libcgroup.git || exit $?
    (cd "$MAKEPKGDIR/libcgroup" && makepkg -si --noconfirm --asdeps) || exit $?
    rm -rf "$MAKEPKGDIR"
}

# Install python-ipy package from the AUR, if it is not already installed
install_python_ipy() {
    local MAKEPKGDIR
    if pacman -Qi python-ipy > /dev/null 2>&1
    then
        return 0
    fi
    MAKEPKGDIR="$(mktemp -d makepkg-python-ipy-XXXXXX)"
    git -C "$MAKEPKGDIR" clone https://aur.archlinux.org/python-ipy.git || exit $?
    (cd "$MAKEPKGDIR/python-ipy" && makepkg -si --noconfirm --asdeps) || exit $?
    rm -rf "$MAKEPKGDIR"
}

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
build_and_install setools3-libs
build_and_install setools MAKEFLAGS="-j1"
build_and_install ustr-selinux
build_and_install libsemanage
build_and_install sepolgen

# policycoreutils depends on pam-selinux and libcgroup (an AUR package)
build_and_install pambase-selinux
build_and_install pam-selinux
install_libcgroup
install_python_ipy
build_and_install policycoreutils

# pacman hook
build_and_install selinux-alpm-hook

# Core packages with SELinux support
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
        '{pacman -U sudo-selinux/sudo-selinux-*.pkg.tar.xz && if test -e /etc/sudoers.pacsave ; then mv /etc/sudoers.pacsave /etc/sudoers ; fi}'
fi

# Handle util-linux/systemd build-time cycle dependency (https://bugs.archlinux.org/task/39767)
if needs_install util-linux-selinux || needs_install systemd-selinux
then
    build util-linux-selinux
    run_conflictual_install pacman -U util-linux-selinux/libutil-linux-selinux-*.pkg.tar.xz
    build systemd-selinux
    run_conflictual_install pacman -U systemd-selinux/libsystemd-selinux-*.pkg.tar.xz
    build_and_install util-linux-selinux
    build_and_install systemd-selinux
fi
build_and_install dbus-selinux

# Kernel with SELinux support
build_and_install linux-selinux

# Reference policy source package
build_and_install selinux-refpolicy-src

# Refpolicy with Arch Linux patches
build_and_install selinux-refpolicy-arch
