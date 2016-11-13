#!/bin/sh
# Provision a Vagrant machine with Arch Linux SELinux packages
# Step 1: build the packages, install them, configure SELinux and reboot

# Exit once a command fails
set -e

if [ "$(id -u)" != 0 ] || ! id vagrant > /dev/null
then
    echo >&2 "This script needs to be run as root in a Vagrant machine."
    exit 1
fi

# Configure the base system and update it
timedatectl set-timezone UTC
# shellcheck disable=SC2016
sed -i -e 's/^#\?MAKEFLAGS=.*/MAKEFLAGS="-j\$(nproc)"/' /etc/makepkg.conf
pacman --noconfirm -Syu

# Build and install SELinux packages
sudo -u vagrant /srv/arch-selinux/recv_gpg_keys.sh
sudo -u vagrant /srv/arch-selinux/clean.sh
install -d -m 755 -o vagrant -g vagrant /build
sudo -u vagrant BUILDDIR=/build /srv/arch-selinux/build_and_install_all.sh
rm -rf /build
pacman --noconfirm -Sc

# Enable new systemd services
systemctl enable auditd.service
systemctl enable restorecond.service

# Configure the bootloader to launch SELinux kernel
if [ -e /etc/default/grub ]
then
    if ! grep 'GRUB_CMDLINE_LINUX=".*selinux=1 security=selinux' /etc/default/grub > /dev/null
    then
        sed -i -e 's/\(GRUB_CMDLINE_LINUX="\)/\1selinux=1 security=selinux /' /etc/default/grub
    fi
    grub-mkconfig -o /boot/grub/grub.cfg
fi
if [ -e /boot/syslinux/syslinux.cfg ]
then
    if ! grep 'APPEND .*selinux=1 security=selinux' /boot/syslinux/syslinux.cfg > /dev/null
    then
        # Replace Arch Linux entries with SELinux kernel
        sed -i -e 's:\(^\s*LINUX \.\./vmlinuz-linux$\):\1-selinux:' /boot/syslinux/syslinux.cfg
        sed -i -e 's:\(^\s*INITRD \.\./initramfs-linux\)\(\(-fallback\)\?\.img$\):\1-selinux\2:' /boot/syslinux/syslinux.cfg
        sed -i -e 's:\(^\s*APPEND \):\1selinux=1 security=selinux :' /boot/syslinux/syslinux.cfg
    fi
fi

# Do not use unconfined module
if semodule -l | grep '^unconfined' > /dev/null
then
    semodule -r unconfined
fi
