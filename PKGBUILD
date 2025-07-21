# Maintainer: Jan Alexander Steffens (heftig) <heftig@archlinux.org>
# Contributor: David Herrmann <dh.herrmann@gmail.com>
# SELinux Maintainer: Nicolas Iooss (nicolas <dot> iooss <at> m4x <dot> org)
#
# This PKGBUILD does not build a variant for dbus-broker-units, as there is nothing specific to SELinux there

pkgbase=dbus-broker-selinux
pkgname=(
  dbus-broker-selinux
)
pkgver=37
pkgrel=2
pkgdesc="Linux D-Bus Message Broker with SELinux support"
url="https://github.com/bus1/dbus-broker/wiki"
arch=(x86_64)
license=(Apache-2.0)
groups=(selinux)
depends=(
  audit
  expat
  gcc-libs
  glibc
  libcap-ng
  systemd-libs
  libselinux
)
makedepends=(
  meson
  python-docutils
  systemd
)
source=(
  https://github.com/bus1/dbus-broker/releases/download/v$pkgver/${pkgbase/-selinux}-$pkgver.tar.xz{,.asc}
  0001-units-Enable-statically.patch
)
b2sums=('151b176882b28190ff23dfdb5c57af18d365a21f7c7fc345df738f4a55388d929331fe4db917bb0dee51f2ebfc872c05f5310dc709cbf5d230944a94d382dd36'
        'SKIP'
        '02e30f49224835af2d327d6c3eecad5509913ad69b75c6b04d00cb4a8a0c9b8e0c043055d43172a215a4e3729527a2f807115117a9b1d1dc27c5f43259a12e36')
validpgpkeys=(
  BE5FBC8C9C1C9F60A4F0AEAE7A4F3A09EBDEFF26  # David Herrmann <dh.herrmann@gmail.com>
)

# https://github.com/bus1/dbus-broker/releases
sha256sums=('f819a8db8795fa08c767612e3823fd594694a0990f2543ecf35d6a1a6bf2ab5b'
            'SKIP'
            '20dcaf03d837d0715f71ccce3d393cba06a4b96f89f4fec3b6e35c1de0592d7d')

prepare() {
  cd ${pkgbase/-selinux}-$pkgver
  patch -Np1 -i ../0001-units-Enable-statically.patch
}

build() {
  local meson_options=(
    -D audit=true
    -D docs=true
    -D linux-4-17=true
    -D system-console-users=gdm,sddm,lightdm,lxdm
    -D selinux=true
  )

  arch-meson ${pkgbase/-selinux}-$pkgver build "${meson_options[@]}"
  meson compile -C build
}

check() {
  meson test -C build --print-errorlogs
}

_pick() {
  local p="$1" f d; shift
  for f; do
    d="$srcdir/$p/${f#$pkgdir/}"
    mkdir -p "$(dirname "$d")"
    mv "$f" "$d"
    rmdir -p --ignore-fail-on-non-empty "$(dirname "$f")"
  done
}

package_dbus-broker-selinux() {
  depends+=(
    libaudit.so
    libcap-ng.so
    libexpat.so
    libsystemd.so
  )
  install=dbus-broker-selinux.install
  provides=("${pkgname/-selinux}")
  conflicts=("${pkgname/-selinux}")

  meson install -C build --destdir "$pkgdir"

  _pick unit "$pkgdir"/usr/lib/systemd/{system,user}/dbus.service
}

# vim:set sw=2 sts=-1 et:
