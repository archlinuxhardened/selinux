# Maintainer: Nicolas Iooss (nicolas <dot> iooss <at> m4x <dot> org)
#
# This PKGBUILD is maintained on https://github.com/archlinuxhardened/selinux.
# If you want to help keep it up to date, please open a Pull Request there.

pkgname=selinux-python
pkgver=3.7
pkgrel=1
pkgdesc="SELinux python tools and libraries"
groups=('selinux')
arch=('i686' 'x86_64' 'aarch64')
url='https://github.com/SELinuxProject/selinux/wiki'
license=('GPL2')
makedepends=('python-pip' 'python-setuptools')
depends=('python' 'python-audit' 'libsemanage>=3.7' 'setools>=4.4.0')
conflicts=('sepolgen<2.7' 'policycoreutils<2.7')
provides=("sepolgen=${pkgver}-${pkgrel}")
validpgpkeys=(
  '63191CE94183098689CAB8DB7EF137EC935B0EAF'  # Jason Zaman <perfinion@gentoo.org>
  'B8682847764DF60DF52D992CBC3905F235179CF1'  # Petr Lautrbach <plautrba@redhat.com>
)
source=("https://github.com/SELinuxProject/selinux/releases/download/${pkgver}/${pkgname}-${pkgver}.tar.gz"{,.asc})
sha256sums=('630b2ad50e017a06a81d4f94312bee85465a93cb050a7536c728055de9a41a2b'
            'SKIP')

build() {
  cd "${pkgbase}-${pkgver}"
  make PYTHON=/usr/bin/python3
}

package() {
  cd "${pkgbase}-${pkgver}"
  make PYTHON=/usr/bin/python3 DESTDIR="${pkgdir}" SBINDIR=/usr/bin install
  /usr/bin/python3 -m compileall "${pkgdir}/$(/usr/bin/python3 -c 'import site; print(site.getsitepackages()[0])')"
}
