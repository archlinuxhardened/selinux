#!/bin/sh
# Install refpolicy in the virtual machine when it is found in a subdirectory.
# This allows testing the latest revision of the reference policy with custom
# patches before they are submitted upstream.
#
# In order to create the refpolicy directory, this command can be used from the
# root directory of this project:
#     cd _vagrant && git clone --recursive https://github.com/SELinuxProject/refpolicy.git
#
# In order to load a policy:
#     vagrant rsync && echo '/vagrant/install_local_refpolicy.sh' | vagrant ssh

# Exit once a command fails
set -e

REFPOL_DIR="$(dirname -- "$0")/refpolicy"

# Ensure that build.conf contains settings suitable to Arch Linux
if ! grep '^DISTRO *= *arch$' "$REFPOL_DIR/build.conf" > /dev/null
then
    echo 'DISTRO = arch' >> "$REFPOL_DIR/build.conf"
fi

# Arch Linux uses systemd
if ! grep '^SYSTEMD *= *y$' "$REFPOL_DIR/build.conf" > /dev/null
then
    echo 'SYSTEMD = y' >> "$REFPOL_DIR/build.conf"
fi

# Let's disable user-based access control for now
if ! grep '^UBAC *= *n$' "$REFPOL_DIR/build.conf" > /dev/null
then
    echo 'UBAC = n' >> "$REFPOL_DIR/build.conf"
fi

make -C "$REFPOL_DIR" clean
make -C "$REFPOL_DIR" conf
make -C "$REFPOL_DIR" all
make -C "$REFPOL_DIR" validate
sudo -s make -C "$REFPOL_DIR" install
sudo -s make -C "$REFPOL_DIR" install-headers
if ! (LANG=C sestatus -v | grep '^Loaded policy name:\s*refpolicy$' > /dev/null)
then
    # Use the new policy
    sudo -s sed -i -e 's/^\(SELINUXTYPE=\).*/SELINUXTYPE=refpolicy/' /etc/selinux/config
fi
sudo -s semodule -s refpolicy -i /usr/share/selinux/refpolicy/*.pp
sudo -s semodule --reload

# Fix the SELinux user of the policy store and configuration
sudo -s restorecon -RF /etc/selinux/ /var/lib/selinux/
echo 'Success: SELinux now uses refpolicy.'
