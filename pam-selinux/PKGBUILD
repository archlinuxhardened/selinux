# Maintainer: Tobias Powalowski <tpowa@archlinux.org>
# Maintainer: Levente Polyak <anthraxx[at]archlinux[dot]org>
# Contributor: judd <jvinet@zeroflux.org>
# SELinux Maintainer: Nicolas Iooss (nicolas <dot> iooss <at> m4x <dot> org)
# SELinux Contributor: Timothée Ravier <tim@siosm.fr>
# SELinux Contributor: Nicky726 <nicky726@gmail.com>
#
# This PKGBUILD is maintained on https://github.com/archlinuxhardened/selinux.
# If you want to help keep it up to date, please open a Pull Request there.

pkgname=pam-selinux
pkgver=1.6.1
pkgrel=2
pkgdesc="SELinux aware PAM (Pluggable Authentication Modules) library"
arch=('x86_64' 'aarch64')
license=('GPL-2.0-only')
url="http://linux-pam.org"
depends=('glibc' 'libtirpc' 'audit' 'libselinux' 'pambase-selinux' 'libaudit.so' 'libxcrypt' 'libcrypt.so' 'libnsl')
makedepends=('flex' 'w3m' 'docbook-xml>=4.4' 'docbook-xsl')
conflicts=("${pkgname/-selinux}" "selinux-${pkgname/-selinux}")
provides=('libpam.so' 'libpamc.so' 'libpam_misc.so'
          "${pkgname/-selinux}=${pkgver}-${pkgrel}"
          "selinux-${pkgname/-selinux}=${pkgver}-${pkgrel}")
backup=(etc/security/{access.conf,faillock.conf,group.conf,limits.conf,namespace.conf,namespace.init,pwhistory.conf,pam_env.conf,time.conf} etc/environment)
groups=('selinux')
source=(https://github.com/linux-pam/linux-pam/releases/download/v$pkgver/Linux-PAM-$pkgver{,-docs}.tar.xz{,.asc}
        ${pkgname/-selinux}.tmpfiles)
validpgpkeys=(
        '8C6BFD92EE0F42EDF91A6A736D1A7F052E5924BB' # Thorsten Kukuk
        '296D6F29A020808E8717A8842DB5BD89A340AEB7' #Dimitry V. Levin <ldv@altlinux.org>
)

sha256sums=('f8923c740159052d719dbfc2a2f81942d68dd34fcaf61c706a02c9b80feeef8e'
            'SKIP'
            'fd7b13b9993c94677e78e84d12387b8da104b5ba668eda3f17360abe4277e79c'
            'SKIP'
            '5631f224e90c4f0459361c2a5b250112e3a91ba849754bb6f67d69d683a2e5ac')

options=('!emptydirs')

prepare() {
  cd Linux-PAM-$pkgver
  # apply patch from the source array (should be a pacman feature)
  local src
  for src in "${source[@]}"; do
    src="${src%%::*}"
    src="${src##*/}"
    [[ $src = *.patch ]] || continue
    echo "Applying patch $src..."
    patch -Np1 < "../$src"
  done
}

build() {
  cd Linux-PAM-$pkgver
  ./configure \
    --libdir=/usr/lib \
    --sbindir=/usr/bin \
    --enable-logind \
    --disable-db \
    --enable-selinux
  make
}

package() {
  install -Dm 644 ${pkgname/-selinux}.tmpfiles "$pkgdir"/usr/lib/tmpfiles.d/${pkgname/-selinux}.conf
  cd Linux-PAM-$pkgver
  make DESTDIR="$pkgdir" SCONFIGDIR=/etc/security install

  # set unix_chkpwd uid
  chmod +s "$pkgdir"/usr/bin/unix_chkpwd
}

# vim: ts=2 sw=2 et:
