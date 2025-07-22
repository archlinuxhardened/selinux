# Substitution for Arch Linux's base -package - SELinux support
# https://wiki.archlinux.org/index.php/SELinux

# Maintainer: Tuomo Kuure <tqre@far.fi>

pkgname=base-selinux
pkgver=2
pkgrel=1
pkgdesc='Minimal packages for Arch Linux installation with SELinux support'
arch=('any')
license=('GPL')
url='https://github.com/archlinuxhardened/selinux'
groups=('selinux')
depends=( 'base'

  # POSIX tools
  'coreutils-selinux' 'findutils-selinux'

  # Standard linux toolset
  'psmisc-selinux' 'shadow-selinux' 'util-linux-selinux'

  # Arch Linux specific
  'systemd-selinux' 'systemd-sysvcompat-selinux' 'selinux-alpm-hook'

  # Networking
  'iproute2-selinux'

  # SELinux packages
  'selinux-refpolicy-arch' 'secilc' 'dbus-selinux' 'selinux-dbus-config' 'mcstrans' 'restorecond'
  'logrotate-selinux' 'checkpolicy'
)
