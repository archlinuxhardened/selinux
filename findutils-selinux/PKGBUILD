# Maintainer: Tobias Powalowski <tpowa@archlinux.org>
# SELinux Maintainer: Nicolas Iooss (nicolas <dot> iooss <at> m4x <dot> org)
# SELinux Contributor: Timothée Ravier
# SELinux Contributor: Nicky726 <Nicky726@gmail.com>
#
# This PKGBUILD is maintained on https://github.com/archlinuxhardened/selinux.
# If you want to help keep it up to date, please open a Pull Request there.

pkgname=findutils-selinux
pkgver=4.10.0
pkgrel=3
pkgdesc="GNU utilities to locate files with SELinux support"
arch=('x86_64' 'aarch64')
license=('GPL-3.0-or-later')
groups=('selinux')
depends=('glibc' 'libselinux')
makedepends=('git' 'wget' 'python')
conflicts=("${pkgname/-selinux}" "selinux-${pkgname/-selinux}")
provides=("${pkgname/-selinux}=${pkgver}-${pkgrel}"
          "selinux-${pkgname/-selinux}=${pkgver}-${pkgrel}")
url='https://www.gnu.org/software/findutils/'
source=("git+https://git.savannah.gnu.org/git/findutils.git?signed#tag=v${pkgver}"
        "git+https://git.savannah.gnu.org/git/gnulib.git")
validpgpkeys=('A5189DB69C1164D33002936646502EF796917195') # Bernhard Voelker <mail@bernhard-voelker.de>
b2sums=('a6d99d922df4c6895d9956a6902518c5f911e6ad1fdcbfc99bb083ce0a725fa4e87bb83a1a2d16e6d900755da9e9094b20f56f971c8e6a6008572cd417fe3e95'
        'SKIP')

prepare() {
  cd "${pkgname/-selinux}"

  git submodule init
  git config submodule.gnulib.url "${srcdir}/gnulib"
  git -c protocol.file.allow=always submodule update

  ./bootstrap
}

build() {
  cd "${pkgname/-selinux}"

  # Don't build or install locate because we use mlocate,
  # which is a secure version of locate.
  sed -e '/^SUBDIRS/s/locate//' -e 's/frcode locate updatedb//' -i Makefile.in

  ./configure --prefix=/usr
  # don't build locate, but the docs want a file in there.
  make -C locate dblocation.texi
  make
}

check() {
  cd "${pkgname/-selinux}"
  make check
}

package() {
  cd "${pkgname/-selinux}"
  make DESTDIR="${pkgdir}" install
}
