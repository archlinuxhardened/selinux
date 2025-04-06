# Maintainer: Jan Alexander Steffens (heftig) <heftig@archlinux.org>
# Contributor: Jan de Groot <jgc@archlinux.org>
# Contributor: Tom Gundersen <teg@jklm.no>
# Contributor: Link Dupont <link@subpop.net>
# SELinux Maintainer: Nicolas Iooss (nicolas <dot> iooss <at> m4x <dot> org)
#
# This PKGBUILD is maintained on https://github.com/archlinuxhardened/selinux.
# If you want to help keep it up to date, please open a Pull Request there.
#
# This PKGBUILD does not build a variant for dbus-daemon-units, as there is nothing specific to SELinux there

pkgbase=dbus-selinux
pkgname=(
  dbus-selinux
  #dbus-daemon-units # Ignore for SELinux package
  dbus-docs-selinux
)
pkgver=1.16.2
pkgrel=1
pkgdesc="Freedesktop.org message bus system with SELinux support"
url="https://www.freedesktop.org/wiki/Software/dbus/"
arch=(x86_64 aarch64)
license=("AFL-2.1 OR GPL-2.0-or-later")
groups=(selinux)
depends=(
  audit
  expat
  glibc
  libcap-ng
  libselinux
  'systemd-libs-selinux>=242.84-2'
)
makedepends=(
  docbook-xsl
  doxygen
  git
  glib2
  mallard-ducktype
  meson
  python
  qt5-tools
  systemd-selinux
  xmlto
  yelp-tools
)
source=(
  "git+https://gitlab.freedesktop.org/dbus/dbus.git?signed#tag=dbus-$pkgver"
  0001-Arch-Linux-tweaks.patch
  dbus-reload.hook
)
b2sums=('669cd4203fbac908db3a20c5b51355d9e84b68c9cc94f8de52e35544a636c6d5d1df8ee2bbdfd6dead53a6bd9865db547aa4af0e913bac697b138c698840d3ce'
        '3896c994aa7afde605aebb88b7123f33c578ad1ede2dc3e76982dbc021d6994874c5c735d31a66c7b3e9d3cba77ebbba7db05013716bbac14948618b1464e4a8'
        '05ab81bf72e7cf45ad943f5b84eaecef4f06bed94979c579a3e23134cbabd7ea6f65fa9ac252f8b43ceb4a3295e0d2325f06560a044fe7ddf125fc30dfc2b7e2')
validpgpkeys=(
  DA98F25C0871C49A59EAFF2C4DE8FF2A63C7CC90  # Simon McVittie <simon.mcvittie@collabora.co.uk>
)

prepare() {
  cd dbus
  patch -Np1 -i ../0001-Arch-Linux-tweaks.patch
}

build() {
  local meson_options=(
    -D apparmor=disabled
    -D dbus_user=dbus
    -D kqueue=disabled
    -D launchd=disabled
    -D relocation=disabled
    -D selinux=enabled
    -D x11_autolaunch=disabled
  )

  arch-meson dbus build "${meson_options[@]}"
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

package_dbus-selinux() {
  depends+=(
    libaudit.so
    libcap-ng.so
    libexpat.so
    libsystemd.so
  )
  provides=(
    libdbus
    libdbus-1.so
    libdbus-selinux 
    "${pkgname/-selinux}=${pkgver}-${pkgrel}"
    "selinux-${pkgname/-selinux}=${pkgver}-${pkgrel}"
  )
  conflicts=(libdbus libdbus-selinux "${pkgname/-selinux}" "selinux-${pkgname/-selinux}")
  replaces=(libdbus libdbus-selinux)

  meson install -C build --destdir "$pkgdir"

  _pick unit "$pkgdir"/usr/lib/systemd/{system,user}/dbus.service
  _pick docs "$pkgdir"/usr/share/doc

  install -Dt "$pkgdir/usr/share/libalpm/hooks" -m644 *.hook

  install -Dt "$pkgdir/usr/share/licenses/$pkgname" -m644 \
    dbus/COPYING dbus/LICENSES/AFL-2.1.txt
}

package_dbus-docs-selinux() {
  pkgdesc+=" - Documentation"
  depends=()
  conflicts=("${pkgname/-selinux}")

  mv docs/* "$pkgdir"

  install -Dt "$pkgdir/usr/share/licenses/$pkgname" -m644 \
    dbus/COPYING dbus/LICENSES/AFL-2.1.txt
}

# vim:set sw=2 sts=-1 et:
