# Maintainer: David Runge <dvzrv@archlinux.org>
# Contributor: Dave Reisner <dreisner@archlinux.org>
# Contributor: Aaron Griffin <aaron@archlinux.org>
# SELinux Maintainer: Nicolas Iooss (nicolas <dot> iooss <at> m4x <dot> org)
# SELinux Contributor: Timothée Ravier <tim@siosm.fr>
# SELinux Contributor: Nicky726 <Nicky726@gmail.com>
# SELinux Contributor: Zezadas
#
# This PKGBUILD is maintained on https://github.com/archlinuxhardened/selinux.
# If you want to help keep it up to date, please open a Pull Request there.

pkgname=shadow-selinux
pkgver=4.14.6
pkgrel=1
pkgdesc="Password and account management tool suite with support for shadow files and PAM - SELinux support"
arch=(x86_64 aarch64)
url="https://github.com/shadow-maint/shadow"
license=(BSD-3-Clause)
groups=(selinux)
depends=(
  glibc
  'libsemanage>=3.2'
)
makedepends=(
  acl
  attr
  audit
  docbook-xsl
  itstool
  libcap
  libxcrypt
  libxslt
  pam-selinux
)
backup=(
  etc/default/useradd
  etc/login.defs
  etc/pam.d/chpasswd
  etc/pam.d/groupmems
  etc/pam.d/newusers
  etc/pam.d/passwd
)
conflicts=("${pkgname/-selinux}" "selinux-${pkgname/-selinux}")
provides=("${pkgname/-selinux}=${pkgver}-${pkgrel}"
          "selinux-${pkgname/-selinux}=${pkgver}-${pkgrel}")
options=(!emptydirs)
# NOTE: distribution patches are taken from https://gitlab.archlinux.org/archlinux/packaging/upstream/shadow/-/commits/4.14.6.arch1
source=(
  $url/releases/download/$pkgver/${pkgname/-selinux}-$pkgver.tar.xz{,.asc}
  0001-Disable-replaced-tools-their-man-pages-and-PAM-integ.patch
  0002-Adapt-login.defs-for-PAM-and-util-linux.patch
  0003-Add-Arch-Linux-defaults-for-login.defs.patch
  shadow.{timer,service}
  shadow.{sysusers,tmpfiles}
  useradd.defaults
)
sha512sums=('994a81afbafb19622a1d0f84527f96a84b0955c4ffa5e826682ead82af7940b8e3a091514bd2075622ebdf7638643c9c6b6b7ac3e48d985278db896249d70ae6'
            'SKIP'
            '3c1d20025c238c1f06960b845854fff6074ad33f9894bacc4943dd320d5e8ec1a7614252d497b6fc8459792d06c00a69f4c50cdcbb8b40e3e59059bdb52b2209'
            '330e22f2dfbe444b42b40c52be352d62cd0b656dc760bea6e40ab0bb8ab210695185a376483c128cf1a889df413de8b990e3ceebf5f2e16b48fb083bcab2a240'
            '54fa3355b67c87d47190ca8bf24557a930fd439e1e197e66989a48d9a819c0bbe8da645be4365142ba3f599ce240d4a092f9df7268dfc41bea92ae0dac378809'
            'e4edf705dd04e088c6b561713eaa1afeb92f42ac13722bff037aede6ac5ad7d4d00828cfb677f7b1ff048db8b6788238c1ab6a71dfcfd3e02ef6cb78ae09a621'
            '2c8689b52029f6aa27d75b8b05b0b36e2fc322cab40fdfbb50cdbe331f61bc84e8db20f012cf9af3de8c4e7fdb10c2d5a4925ca1ba3b70eb5627772b94da84b3'
            '5afac4a96b599b0b8ed7be751e7160037c3beb191629928c6520bfd3f2adcd1c55c31029c92c2ff8543e6cd9e37e2cd515ba4e1789c6d66f9c93b4e7f209ee7a'
            '97a6a57c07502e02669dc1a91bffc447dba7d98d208b798d80e07de0d2fdf9d23264453978d2d3d1ba6652ca1f2e22cdadc4309c7b311e83fa71b00ad144f877'
            '706ba6e7fa8298475f2605a28daffef421c9fa8d269cbd5cbcf7f7cb795b40a24d52c20e8d0b73e29e6cd35cd7226b3e9738dc513703e87dde04c1d24087a69c')
b2sums=('e910131eab6527c1222afadf02ebd7bd6a3460baf95c23cc9eefa7aa21ddb70c02e58e4f58db2cb24fa8e2996c82b11664420545a8b1af573e4e6a25ceb3f921'
        'SKIP'
        '565f625b3794aabd68fcb7e72a50a48109674b6650073c5f757b7722f51d4b42dc60ad290b9e24bbd2de41528751c6fa3d1d3b6e69c34576d3568b4f4f625bf6'
        '0ea92cade7824c40542dbf1e1c964dc729c92beaa25632f5ee60f89ec9d2ba0c699149af064c057ed68242f85b835d6f9f4d185838fa91efbcbb97c6175883de'
        '9ac5719a6f0fc0cae436dda9e8dd3eb8ced4702ee3812db777198e61232d575dbb6be46ef3bbacf39b9c3938dfe0a6e4d00ce0e44fcf3769ec93e68e7365f3fd'
        '5cfc936555aa2b2e15f8830ff83764dad6e11a80e2a102c5f2bd3b7c83db22a5457a3afdd182e3648c9d7d5bca90fa550f59576d0ac47a11a31dfb636cb18f2b'
        'a69191ab966f146c35e7e911e7e57c29fffd54436ea014aa8ffe0dd46aaf57c635d0a652b35916745c75d82b3fca7234366ea5f810b622e94730b45ec86f122c'
        '511c4ad9f3be530dc17dd68f2a3387d748dcdb84192d35f296b88f82442224477e2a74b1841ec3f107b39a5c41c2d961480e396a48d0578f8fd5f65dbe8d9f04'
        'd727923dc6ed02e90ef31f10b3427df50afbfe416bd03c6de0c341857d1bb33ab6168312bd4ba18d19d0653020fb332cbcfeeb24e668ae3916add9d01b89ccb4'
        'f743922062494fe342036b3acb8b747429eb33b1a13aa150daa4bb71a84e9c570cfcc8527a5f846e3ea7020e6f23c0b10d78cf2ba8363eea0224e4c34ea10161')
validpgpkeys=(
  66D0387DB85D320F8408166DB175CFA98F192AF2  # Serge Hallyn <sergeh@kernel.org>
  A9348594CE31283A826FBDD8D57633D441E25BB5  # Alejandro Colomar <alx@kernel.org>
)

prepare() {
  local filename

  cd "${pkgname/-selinux}-$pkgver"
  for filename in "${source[@]}"; do
    if [[ "$filename" =~ \.patch$ ]]; then
      printf "Applying patch %s\n" "${filename##*/}"
      patch -Np1 -i "$srcdir/${filename##*/}"
    fi
  done

  autoreconf -fiv
}

build() {
  local configure_options=(
    --bindir=/usr/bin
    --disable-account-tools-setuid  # no setuid for chgpasswd, chpasswd, groupadd, groupdel, groupmod, newusers, useradd, userdel, usermod
    --enable-man
    --libdir=/usr/lib
    --mandir=/usr/share/man
    --prefix=/usr
    --sbindir=/usr/bin
    --sysconfdir=/etc
    --with-audit
    --with-fcaps  # use capabilities instead of setuid for setuidmap and setgidmap
    --with-group-name-max-length=32
    --with-libpam  # PAM integration for chpasswd, groupmems, newusers, passwd
    --with-yescrypt
    --without-libbsd  # shadow can use internal implementation for getting passphrase
    --without-nscd  # we do not ship nscd anymore
    --with-selinux
    --without-su  # su is provided by util-linux
  )

  cd "${pkgname/-selinux}-$pkgver"
  # add extra check, preventing accidental deletion of other user's home dirs when using `userdel -r <user with home in />`
  export CFLAGS="$CFLAGS -DEXTRA_CHECK_HOME_DIR"
  ./configure "${configure_options[@]}"

  # prevent excessive overlinking due to libtool
  sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
  make
}

package() {
  depends+=(
    acl libacl.so
    attr libattr.so
    audit libaudit.so
    libxcrypt libcrypt.so
    pam libpam.so libpam_misc.so
  )

  cd "${pkgname/-selinux}-$pkgver"

  make DESTDIR="$pkgdir" install
  make DESTDIR="$pkgdir" -C man install

  # license
  install -vDm 644 COPYING -t "$pkgdir/usr/share/licenses/$pkgname/"

  # custom useradd(8) defaults (not provided by upstream)
  install -vDm 600 ../useradd.defaults "$pkgdir/etc/default/useradd"

  # systemd units
  install -vDm 644 ../shadow.timer -t "$pkgdir/usr/lib/systemd/system/"
  install -vDm 644 ../shadow.service -t "$pkgdir/usr/lib/systemd/system/"
  install -vdm 755 "$pkgdir/usr/lib/systemd/system/timers.target.wants"
  ln -s ../shadow.timer "$pkgdir/usr/lib/systemd/system/timers.target.wants/shadow.timer"

  install -vDm 644 ../${pkgname/-selinux}.sysusers "$pkgdir/usr/lib/sysusers.d/${pkgname/-selinux}.conf"
  install -vDm 644 ../${pkgname/-selinux}.tmpfiles "$pkgdir/usr/lib/tmpfiles.d/${pkgname/-selinux}.conf"

  # adapt executables to match the modes used by tmpfiles.d, so that pacman does not complain:
  chmod 750 "$pkgdir/usr/bin/groupmems"
}
