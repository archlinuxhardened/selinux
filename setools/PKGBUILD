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
pkgver=4.5.1
pkgrel=3
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
checkdepends=('checkpolicy' 'pyside6' 'python-pytest' 'python-pytest-qt')
conflicts=("selinux-${pkgname}")
provides=("selinux-${pkgname}=${pkgver}-${pkgrel}")
source=("https://github.com/SELinuxProject/setools/releases/download/${pkgver}/${pkgname}-${pkgver}.tar.bz2"
        0001-setup.py-Move-static-definitions-to-pyproject.toml.patch
)
sha256sums=('25e47d00bbffd6046f55409c9ba3b08d9b1d5788cc159ea247d9e0ced8e482e7'
            '27fd3673709767038fcd5253f13a057dac48b5c6884e07507ff3f1461223cd21')

prepare() {
  cd "${pkgname}"
  patch -Np1 -i "../0001-setup.py-Move-static-definitions-to-pyproject.toml.patch"
}

build() {
  cd "${pkgname}"
  python setup.py build_ext
  python setup.py build
}

check() {
  cd "${pkgname}"
  # Instructions from https://github.com/SELinuxProject/setools/blob/4.5.1/README.md#unit-tests
  python setup.py build_ext -i
  pytest tests
}

package() {
  cd "${pkgname}"
  python setup.py install --root="$pkgdir" --optimize=1 --skip-build
}
