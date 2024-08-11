# Maintainer: Nicolas Iooss (nicolas <dot> iooss <at> m4x <dot> org)
#
# This PKGBUILD is maintained on https://github.com/archlinuxhardened/selinux.
# If you want to help keep it up to date, please open a Pull Request there.

pkgname=semodule-utils
pkgver=3.7
pkgrel=1
pkgdesc="SELinux module tools"
arch=('i686' 'x86_64' 'aarch64')
url='https://github.com/SELinuxProject/selinux/wiki'
license=('GPL2')
groups=('selinux')
depends=('libsepol>=2.7')
conflicts=('policycoreutils<2.7')
validpgpkeys=(
  '63191CE94183098689CAB8DB7EF137EC935B0EAF'  # Jason Zaman <perfinion@gentoo.org>
  'B8682847764DF60DF52D992CBC3905F235179CF1'  # Petr Lautrbach <plautrba@redhat.com>
)
source=("https://github.com/SELinuxProject/selinux/releases/download/${pkgver}/${pkgname}-${pkgver}.tar.gz"{,.asc})
sha256sums=('db0641aeafefec46612c7c2ddd33ef1060bb721ce64842d2a96c33dddb5eb176'
            'SKIP')

build() {
  cd "${pkgname}-${pkgver}"
  make
}

package() {
  cd "${pkgname}-${pkgver}"
  make DESTDIR="${pkgdir}" install
}
