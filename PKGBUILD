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
pkgver=9.7
pkgrel=1
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
)
validpgpkeys=(
 6C37DC12121A5006BC1DB804DF6FD971306037D9 # Pádraig Brady
)
b2sums=('9c18801f93853f6f78919f79ce84256260e9f5fa5f496e73ac8b9e2c66106cdcd808fe971f6c064cf4f9a97aae4dd4afc97126a8ac89b59497557f89a3734bab'
        'SKIP')

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

