# Maintainer: Nicolas Iooss (nicolas <dot> iooss <at> m4x <dot> org)
#
# This PKGBUILD is maintained on https://github.com/archlinuxhardened/selinux.
# If you want to help keep it up to date, please open a Pull Request there.

pkgname=selinux-gui
pkgver=3.9
pkgrel=1
pkgdesc="SELinux GUI tools"
groups=('selinux')
arch=('any')
url='https://github.com/SELinuxProject/selinux/wiki'
license=('GPL2')
depends=('python-gobject' 'hicolor-icon-theme' 'selinux-python' 'gtk3')
conflicts=('policycoreutils<2.7')
validpgpkeys=(
  '63191CE94183098689CAB8DB7EF137EC935B0EAF'  # Jason Zaman <perfinion@gentoo.org>
  '68D21823342A13683AEB3E4EFB4C685B5DC1C13E'  # Petr Lautrbach <lautrbach@redhat.com>
)
source=("https://github.com/SELinuxProject/selinux/releases/download/${pkgver}/${pkgname}-${pkgver}.tar.gz"{,.asc})
sha256sums=('2a2af398aef51d7d392c0f4b4cca0780d5ac575466927c1b09c306888a8a2c65'
            'SKIP')

build() {
  cd "${pkgname}-${pkgver}"
  make
}

package() {
  cd "${pkgname}-${pkgver}"
  make DESTDIR="${pkgdir}" install

  # Compile Python files into bytecode
  python -m compileall "${pkgdir}/usr/share/system-config-selinux"
}
