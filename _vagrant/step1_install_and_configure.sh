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

# Unfortunately, setting the timezone with timedatectl breaks when a
# dependency of systemd (like libidn2) is updated.
# Do not make the failure of this command fatal.
timedatectl set-timezone UTC || true

# Configure the base system and update it
# shellcheck disable=SC2016
sed -i -e 's/^#\?MAKEFLAGS=.*/MAKEFLAGS="-j\$(nproc)"/' /etc/makepkg.conf
pacman --noconfirm -Sy archlinux-keyring
pacman --noconfirm -Syu

# Install haveged in order to speed up the launch of SSH server
if ! pacman -Qi haveged > /dev/null 2>&1
then
    pacman --noconfirm -S haveged
    systemctl start haveged.service
    systemctl enable haveged.service
fi

# Build and install SELinux packages
sudo -su vagrant /srv/arch-selinux/recv_gpg_keys.sh
sudo -su vagrant /srv/arch-selinux/clean.sh
sudo -su vagrant rm -rf /home/vagrant/.tmp/build
sudo -su vagrant mkdir -p /home/vagrant/.tmp/build
sudo -su vagrant BUILDDIR=/home/vagrant/.tmp/build /srv/arch-selinux/build_and_install_all.sh -g
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
        # Enable SELinux in kernel command line
        sed -i -e 's:\(^\s*APPEND \):\1selinux=1 security=selinux :' /boot/syslinux/syslinux.cfg
    fi
    # If using the deprecated linux-selinux kernel, replace the entries
    if grep 'LINUX \.\./vmlinuz-linux-selinux' /boot/syslinux/syslinux.cfg > /dev/null
    then
        sed -i -e 's:\(^\s*LINUX \.\./vmlinuz-linux\)-selinux$:\1:' /boot/syslinux/syslinux.cfg
        sed -i -e 's:\(^\s*INITRD \.\./initramfs-linux\)-selinux\(\(-fallback\)\?\.img\)$:\1\2:' /boot/syslinux/syslinux.cfg
    fi
fi

if [ -d /vagrant/refpolicy ]
then
    /vagrant/install_local_refpolicy.sh
fi

# Do not use unconfined module
if semodule -l | grep '^unconfined' > /dev/null
then
    semodule -r unconfined
fi

# Install the custom policy module
semodule --verbose -i /vagrant/vagrant-custom.cil
