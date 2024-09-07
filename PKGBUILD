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
pkgrel=3
pkgdesc="SELinux aware PAM (Pluggable Authentication Modules) library"
arch=('x86_64' 'aarch64')
license=('GPL-2.0-only')
url="http://linux-pam.org"
depends=('glibc' 'libtirpc' 'audit' 'libselinux' 'pambase-selinux' 'libaudit.so' 'libxcrypt' 'libcrypt.so' 'libnsl' 'systemd-libs')
makedepends=('git' 'flex' 'w3m' 'libxslt' 'docbook-xml' 'docbook5-xml' 'docbook-xsl' 'fop')
conflicts=("${pkgname/-selinux}" "selinux-${pkgname/-selinux}")
provides=('libpam.so' 'libpamc.so' 'libpam_misc.so'
          "${pkgname/-selinux}=${pkgver}-${pkgrel}"
          "selinux-${pkgname/-selinux}=${pkgver}-${pkgrel}")
backup=(etc/security/{access.conf,faillock.conf,group.conf,limits.conf,namespace.conf,namespace.init,pwhistory.conf,pam_env.conf,time.conf} etc/environment)
groups=('selinux')
source=("pam::git+https://github.com/linux-pam/linux-pam?signed#tag=v${pkgver}"
        "${pkgname/-selinux}.tmpfiles")
validpgpkeys=(
        '8C6BFD92EE0F42EDF91A6A736D1A7F052E5924BB' # Thorsten Kukuk
        '296D6F29A020808E8717A8842DB5BD89A340AEB7' # Dimitry V. Levin <ldv@altlinux.org>
)
b2sums=('12891f9064ce7f00d22452d8ff39c14af87c24f9fbf3eab65e475a7d2a592d2b1c1d585f3718b2fa72f277a8ad1faa17149fe0a911bfabdaa4a2957c32e29fe3'
        '36582c80020008c3810b311a2e126d2fb4ffc94e565ea4c0c0ab567fdb92943e269781ffa548550742feb685847c26c340906c7454dcc31df4e1e47d511d8d6f')
options=('!emptydirs')

prepare() {
  cd "${pkgname/-selinux}"
  ./autogen.sh
  # apply patch from the source array (should be a pacman feature)
  local src
  for src in "${source[@]}"; do
    src="${src%%::*}"
    src="${src##*/}"
    [[ $src = *.patch ]] || continue
    echo "Applying patch ${src}..."
    patch -Np1 < "../${src}"
  done
}

build() {
  cd "${pkgname/-selinux}"
  ./configure \
    --libdir=/usr/lib \
    --sbindir=/usr/bin \
    --enable-logind \
    --disable-db \
    --enable-selinux
  make
}

package() {
  install -Dm 644 ${pkgname/-selinux}.tmpfiles "${pkgdir}"/usr/lib/tmpfiles.d/${pkgname/-selinux}.conf
  cd "${pkgname/-selinux}"
  make DESTDIR="${pkgdir}" SCONFIGDIR=/etc/security install

  # set unix_chkpwd uid
  chmod +s "${pkgdir}"/usr/bin/unix_chkpwd
}

