#!/bin/sh
# Step 2: relabel all files

set -e

# Fail early if not booted with SELinux
if ! (LANG=C sestatus | grep '^SELinux status: *enabled')
then
    echo >&2 "SELinux is not enabled. Step 1 failed!"
    exit 1
fi

# Allow SSH login for sysadm_u
semanage boolean --modify --on ssh_sysadm_login

# Allow every domain to use /dev/urandom
semanage boolean --modify --on global_ssp

# Allow users to send ping
semanage boolean --modify --on user_ping

# Allow systemd-tmpfiles to manage every file
semanage boolean --modify --on systemd_tmpfiles_manage_all

# Make vagrant user use sysadm_u context
if ! (semanage login -l | grep '^vagrant' > /dev/null)
then
    echo "Configuring SELinux context for vagrant user"
    semanage login -a -s sysadm_u vagrant
fi

# Label /srv/arch-selinux and /vagrant as vagrant's home files
if semanage fcontext --list | grep '^/srv/arch-selinux(/\.\*)?'
then
    semanage fcontext -m -s sysadm_u -t user_home_t '/srv/arch-selinux(/.*)?'
else
    semanage fcontext -a -s sysadm_u -t user_home_t '/srv/arch-selinux(/.*)?'
fi
if semanage fcontext --list | grep '^/vagrant(/\.\*)?'
then
    semanage fcontext -m -s sysadm_u -t user_home_t '/vagrant(/.*)?'
else
    semanage fcontext -a -s sysadm_u -t user_home_t '/vagrant(/.*)?'
fi

# On systems with syslinux, ldlinux.sys is immutable but needs to be relabelled
if [ -e /boot/syslinux/ldlinux.sys ]
then
    if ! (getfilecon /boot/syslinux/ldlinux.sys | grep system_u:object_r:boot_t > /dev/null)
    then
        chattr -i /boot/syslinux/ldlinux.sys
        restorecon -vF /boot/syslinux/ldlinux.sys
        syslinux-install_update -u
    fi
fi

echo "Relabelling the system..."
restorecon -RF /
