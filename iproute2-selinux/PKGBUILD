# Maintainer: Christian Hesse <mail@eworm.de>
# Maintainer: Ronald van Haren <ronald.archlinux.org>
# Contributor: Judd Vinet <jvinet@zeroflux.org>
# SELinux Maintainer: Nicolas Iooss (nicolas <dot> iooss <at> m4x <dot> org)
#
# This PKGBUILD is maintained on https://github.com/archlinuxhardened/selinux.
# If you want to help keep it up to date, please open a Pull Request there.

pkgname=iproute2-selinux
pkgver=6.17.0
pkgrel=1
pkgdesc='IP Routing Utilities with SELinux support'
arch=('x86_64' 'aarch64')
license=('GPL-2.0-or-later')
groups=('selinux')
url='https://git.kernel.org/pub/scm/network/iproute2/iproute2.git'
depends=('glibc'
         'libxtables.so' # from iptables or iptables-nft
         'libcap' 'libcap.so'
         'libelf'
         'libbpf' 'libbpf.so'
         'libselinux')
makedepends=('git' 'db5.3' 'linux-atm' 'iptables')
optdepends=('db5.3: userspace arp daemon'
            'linux-atm: ATM support'
            'python: for routel')
provides=('iproute' "${pkgname/-selinux}=${pkgver}-${pkgrel}")
conflicts=("${pkgname/-selinux}")
options=('!emptydirs')
validpgpkeys=('9F6FC345B05BE7E766B83C8F80A77F6095CDE47E') # Stephen Hemminger
source=("git+https://git.kernel.org/pub/scm/network/${pkgname/-selinux}/${pkgname/-selinux}.git#tag=v${pkgver}"
        '0001-make-iproute2-fhs-compliant.patch'
        '0002-bdb-5-3.patch')
sha256sums=('3f1bb15ca13e90ac4c001f1e763fd90c56b1c7aaedb076ae3aa68ebb303e925e'
            '758b82bd61ed7512d215efafd5fab5ae7a28fbfa6161b85e2ce7373285e56a5d'
            '611c1ad7946aab226a5f4059922d9430f51b3377e33911427f8fdf7f7d31f7d6')

prepare() {
  cd "${srcdir}/${pkgname/-selinux}"

  # set correct fhs structure
  patch -Np1 -i "${srcdir}"/0001-make-iproute2-fhs-compliant.patch

  # use Berkeley DB 5.3
  patch -Np1 -i "${srcdir}"/0002-bdb-5-3.patch
}

build() {
  cd "${srcdir}/${pkgname/-selinux}"

  # ./configure auto-detects SELinux as a build dependency for "ss":
  # https://git.kernel.org/pub/scm/network/iproute2/iproute2.git/tree/configure?h=v5.14.0#n373
  ./configure
  make DBM_INCLUDE='/usr/include/db5.3'
}

package() {
  cd "${srcdir}/${pkgname/-selinux}"

  make DESTDIR="${pkgdir}" SBINDIR="/usr/bin" install
}
