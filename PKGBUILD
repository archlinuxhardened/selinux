# Maintainer: Sébastien "Seblu" Luttringer
# Maintainer: Tobias Powalowski <tpowa@archlinux.org>
# Contributor: Bartłomiej Piotrowski <bpiotrowski@archlinux.org>
# Contributor: Allan McRae <allan@archlinux.org>
# Contributor: judd <jvinet@zeroflux.org>
# SELinux Maintainer: Nicolas Iooss (nicolas <dot> iooss <at> m4x <dot> org)
# SELinux Contributor: Timothée Ravier <tim@siosm.fr>
# SELinux Contributor: Nicky726 (Nicky726 <at> gmail <dot> com)
#
# This PKGBUILD is maintained on https://github.com/archlinuxhardened/selinux.
# If you want to help keep it up to date, please open a Pull Request there.

pkgname=coreutils-selinux
pkgver=9.6
pkgrel=4
pkgdesc='The basic file, shell and text manipulation utilities of the GNU operating system with SELinux support'
arch=('x86_64' 'aarch64')
license=(
  GPL-3.0-or-later
  GFDL-1.3-or-later
)
url='https://www.gnu.org/software/coreutils/'
groups=('selinux')
depends=( 
  acl  
  attr
  glibc
  gmp
  libcap
  libselinux
  openssl
)
makedepends=(
  git
  gperf
  python
  wget
)
conflicts=("${pkgname/-selinux}" "selinux-${pkgname/-selinux}")
provides=("${pkgname/-selinux}=${pkgver}-${pkgrel}"
          "selinux-${pkgname/-selinux}=${pkgver}-${pkgrel}")
source=(
  git+https://git.savannah.gnu.org/git/coreutils.git?signed#tag=v${pkgver}
  git+https://git.savannah.gnu.org/git/gnulib.git
  ${pkgname/-selinux}-9.6-fix-ls-crash.patch  # https://git.savannah.gnu.org/gitweb/?p=coreutils.git;a=patch;h=915004f403cb25fadb207ddfdbe6a2f43bd44fac
  ${pkgname/-selinux}-9.6-cat-crash.patch # https://git.savannah.gnu.org/gitweb/?p=coreutils.git;a=patch;h=7386c291be8e2de115f2e161886e872429edadd7
)
validpgpkeys=(
 6C37DC12121A5006BC1DB804DF6FD971306037D9 # Pádraig Brady
)
b2sums=('8d8ee559af5401564314c87e6b2affb670d6de59546b23dab3fa5235d6d3c71f841f91dcb6daf9bf38db25ebc3c21db4f9a536568744fabe3d02bcf9430c90ca'
        'SKIP'
        'd365086f33ffd770c8f457348561ed4120919c84f1bd4126495cd339f85a1fbf99845e1b17032a4ea579a93986f45ad71add1cd997e6a43235852087eac1279d'
        'f2d56b36ed9689fc7b879eb2985ad6aaeb8f50e5c1e7ac3b1ae064aad91d06198ea021f98792e7fb50994aa25f37a72edfcae40c59371427d477399327e2a8f1')

prepare() {
  cd "${pkgname/-selinux}"

  git submodule init
  git config submodule.gnulib.url ../gnulib
  git -c protocol.file.allow=always submodule update

  ./bootstrap

  # apply patch from the source array (should be a pacman feature)
  local src
  for src in "${source[@]}"; do
    src="${src%%::*}"
    src="${src##*/}"
    [[ $src = *.patch ]] || continue
    echo "Applying patch $src..."
    patch -Np1 < "../$src"
  done

  # tail -F fails to find out that files are removed, in test VM
  # so disable the tests which verify this
  sed '/^  tests\/tail\/assert\.sh\s/d' -i tests/local.mk
  sed '/^  tests\/tail\/inotify-dir-recreate\.sh\s/d' -i tests/local.mk

  # some tests create directories with long name, which does not work on GitHub Actions
  sed '/^  tests\/du\/long-from-unreadable\.sh\s/d' -i tests/local.mk
  sed '/^  tests\/rm\/deep-2\.sh\s/d' -i tests/local.mk
}

build() {
  cd "${pkgname/-selinux}"
  aclocal -I m4
  autoconf -f
  autoheader -f
  automake -f
  ./configure \
    --prefix=/usr \
    --libexecdir=/usr/lib \
    --with-openssl \
    --enable-no-install-program=hostname,kill,uptime \
    --with-selinux
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

