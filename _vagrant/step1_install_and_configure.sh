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
sudo -u vagrant mkdir -p /home/vagrant/.tmp/build
sudo -u vagrant BUILDDIR=/home/vagrant/.tmp/build LANG=en_US.UTF-8 /srv/arch-selinux/build_and_install_all.sh -g
rm -rf /home/vagrant/.tmp/build
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

# Use upstream refpolicy if it is cloned in _vagrant/refpolicy/ with for example:
#     git clone --recursive https://github.com/TresysTechnology/refpolicy.git
REFPOL_DIR=/vagrant/refpolicy
if [ -d "$REFPOL_DIR" ]
then
    # Ensure that build.conf contains settings suitable to Arch Linux
    if ! grep '^DISTRO *= *arch$' "$REFPOL_DIR/build.conf"
    then
        echo 'DISTRO = arch' >> "$REFPOL_DIR/build.conf"
    fi

    # Arch Linux uses systemd
    if ! grep '^SYSTEMD *= *y$' "$REFPOL_DIR/build.conf"
    then
        echo 'SYSTEMD = y' >> "$REFPOL_DIR/build.conf"
    fi

    # Let's disable user-based access control for now
    if ! grep '^UBAC *= *n$' "$REFPOL_DIR/build.conf"
    then
        echo 'UBAC = n' >> "$REFPOL_DIR/build.conf"
    fi

    make -C "$REFPOL_DIR" conf
    make -C "$REFPOL_DIR" all
    make -C "$REFPOL_DIR" validate
    make -C "$REFPOL_DIR" install
    make -C "$REFPOL_DIR" install-headers
    sed -i -e 's/^\(SELINUXTYPE=\).*/SELINUXTYPE=refpolicy/' /etc/selinux/config
    semodule -s refpolicy -i /usr/share/selinux/refpolicy/*.pp
fi

# Do not use unconfined module
if semodule -l | grep '^unconfined' > /dev/null
then
    semodule -r unconfined
fi
