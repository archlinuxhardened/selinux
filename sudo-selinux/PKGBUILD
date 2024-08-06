# Maintainer: Evangelos Foutras <foutrelis@archlinux.org>
# Contributor: Allan McRae <allan@archlinux.org>
# Contributor: Tom Newsom <Jeepster@gmx.co.uk>
# SELinux Maintainer: Nicolas Iooss (nicolas <dot> iooss <at> m4x <dot> org)
# SELinux Contributor: Timothée Ravier <tim@siosm.fr>
# SELinux Contributor: Nicky726 <Nicky726@gmail.com>
#
# This PKGBUILD is maintained on https://github.com/archlinuxhardened/selinux.
# If you want to help keep it up to date, please open a Pull Request there.

pkgname=sudo-selinux
_sudover=1.9.15p5
pkgrel=2
pkgver=${_sudover/p/.p}
pkgdesc="Give certain users the ability to run some commands as root - SELinux support"
arch=('x86_64' 'aarch64')
url="https://www.sudo.ws/sudo/"
license=('custom')
groups=('selinux')
depends=('glibc' 'openssl' 'pam-selinux' 'libldap' 'zlib' 'libselinux')
conflicts=("${pkgname/-selinux}" "selinux-${pkgname/-selinux}")
provides=("${pkgname/-selinux}=${pkgver}-${pkgrel}"
          "selinux-${pkgname/-selinux}=${pkgver}-${pkgrel}")
backup=('etc/pam.d/sudo'
        'etc/sudo.conf'
        'etc/sudo_logsrvd.conf'
        'etc/sudoers')
install=${pkgname/-selinux}.install
source=(https://www.sudo.ws/sudo/dist/${pkgname/-selinux}-$_sudover.tar.gz{,.sig}
        $pkgname-preserve-editor-for-visudo.patch::https://github.com/sudo-project/sudo/commit/1db1453556e1.patch
        $pkgname-enable-secure_path-by-default.patch::https://github.com/sudo-project/sudo/commit/e0e24456bc3f.patch
        $pkgname-add-with-secure-path-value-option.patch::https://github.com/sudo-project/sudo/commit/e24737eac90f.patch
        sudo_logsrvd.service
        sudo.pam)
sha256sums=('558d10b9a1991fb3b9fa7fa7b07ec4405b7aefb5b3cb0b0871dbc81e3a88e558'
            'SKIP'
            '321aa5f1b482ffd5728c07477a51ce3de1e48b9db13f4578e662c227c705826c'
            'baacece8e854bed47276925715ae8f3c2771ad72821006b3a26796fe154e1130'
            '78cc8346d79b359d89e8b2e27485eab8b076fab72e0c74832fa994407c3c6147'
            'bd4bc2f5d85cbe14d7e7acc5008cb4fe62c38de7d42dc6876c87bfaa273c0a6e'
            'd1738818070684a5d2c9b26224906aad69a4fea77aabd960fc2675aee2df1fa2')
validpgpkeys=('59D1E9CCBA2B376704FDD35BA9F4C021CEA470FB')

prepare() {
  cd "${pkgname/-selinux}-$_sudover"
  patch -Np1 -i ../$pkgname-preserve-editor-for-visudo.patch
  patch -Np1 -F3 -i ../$pkgname-enable-secure_path-by-default.patch
  patch -Np1 -i ../$pkgname-add-with-secure-path-value-option.patch
}

build() {
  cd "${pkgname/-selinux}-$_sudover"

  ./configure \
    --prefix=/usr \
    --sbindir=/usr/bin \
    --libexecdir=/usr/lib \
    --with-rundir=/run/sudo \
    --with-vardir=/var/db/sudo \
    --with-logfac=auth \
    --enable-tmpfiles.d \
    --with-pam \
    --with-sssd \
    --with-ldap \
    --with-ldap-conf-file=/etc/openldap/ldap.conf \
    --with-env-editor \
    --with-passprompt="[sudo] password for %p: " \
    --with-secure-path-value=/usr/local/sbin:/usr/local/bin:/usr/bin \
    --with-all-insults \
    --with-selinux
  make
}

check() {
  cd "${pkgname/-selinux}-$_sudover"
  make check
}

package() {
  depends+=('libcrypto.so' 'libssl.so')

  cd "$srcdir/${pkgname/-selinux}-$_sudover"
  make DESTDIR="$pkgdir" install

  # sudo_logsrvd service file (taken from sudo-logsrvd-1.9.0-1.el8.x86_64.rpm)
  install -Dm644 -t "$pkgdir/usr/lib/systemd/system" ../sudo_logsrvd.service

  # Remove sudoers.dist; not needed since pacman manages updates to sudoers
  rm "$pkgdir/etc/sudoers.dist"

  # Remove /run/sudo directory; we create it using systemd-tmpfiles
  rmdir "$pkgdir/run/sudo"
  rmdir "$pkgdir/run"

  install -Dm644 "$srcdir/sudo.pam" "$pkgdir/etc/pam.d/sudo"

  install -Dm644 LICENSE.md -t "$pkgdir/usr/share/licenses/sudo-selinux"
}

# vim:set ts=2 sw=2 et:
