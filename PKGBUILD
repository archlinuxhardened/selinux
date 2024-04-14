# Maintainer: Nicolas Iooss (nicolas <dot> iooss <at> m4x <dot> org)
# Contributor: Timothée Ravier <tim@siosm.fr>
# Contributor: Nicky726 <Nicky726 [at] gmail [dot] com>
# Contributor: Xiao-Long Chen <chenxiaolong@cxl.epac.to>
#
# This PKGBUILD is maintained on https://github.com/archlinuxhardened/selinux.
# If you want to help keep it up to date, please open a Pull Request there.

# /!\ Important note when upgrading from setools 3 /!\
# When upgrading with policycoreutils 2.5-3, pacman fails with:
#    failed to prepare transaction (could not satisfy dependencies)
#    :: policycoreutils: installing setools (4.0.1-1) breaks dependency 'setools3-libs'
# In order to upgrade setools, you can either:
#   - build setools 4.0.1-1 and setools3-libs 3.3.8-1 and install both packages
#     at the same time (with a single "pacman -U" command)
#   - temporarily uninstall policycoreutils while upgrading and install it
#     again afterwards, or
#   - replace setools 3.3.8 with setools3-libs and install setools then.

pkgname=setools
pkgver=4.5.0
pkgrel=1
pkgdesc="Policy analysis tools for SELinux"
groups=('selinux')
arch=('i686' 'x86_64' 'aarch64')
url="https://github.com/SELinuxProject/setools/wiki"
license=('GPL' 'LGPL')
depends=('libsepol>=3.2' 'libselinux>=3.2' 'python' 'python-networkx>=2.6' 'python-setuptools')
optdepends=('python-graphviz: for seinfoflow, sedta, apol'
            'python-pyqt6: needed for graphical tools'
            'qt6-tools: display apol help with Qt Assistant')
makedepends=('cython' 'python-tox')
checkdepends=('checkpolicy' 'python-pytest')
conflicts=("selinux-${pkgname}")
provides=("selinux-${pkgname}=${pkgver}-${pkgrel}")
source=("https://github.com/SELinuxProject/setools/releases/download/${pkgver}/${pkgname}-${pkgver}.tar.bz2")
sha256sums=('68469ae9bd114b42bba4cb41795577ca1e4f50e3e4234817f13ff1a8bbd9ce77')

prepare() {
  cd "${pkgname}"

  # Fix https://github.com/SELinuxProject/setools/issues/124
  sed "s/package_data={'': \['\*\.html'\],/package_data={'': ['*.html', '*.css'],/" -i setup.py
}

build() {
  cd "${pkgname}"
  python setup.py build_ext
  python setup.py build
}

check() {
  cd "${pkgname}"
  python setup.py test
}

package() {
  cd "${pkgname}"
  python setup.py install --root="$pkgdir" --optimize=1 --skip-build
}
