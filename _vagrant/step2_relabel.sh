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

echo "Relabelling the system..."
restorecon -RF /
