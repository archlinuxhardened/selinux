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
pkgver=4.17.3
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
  git
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
# NOTE: distribution patches are taken from https://gitlab.archlinux.org/archlinux/packaging/upstream/shadow/-/commits/4.17.3.arch2
source=(
  git+$url.git?signed#tag=$pkgver
  0001-Disable-replaced-tools-their-man-pages-and-PAM-integ.patch
  0002-Adapt-login.defs-for-PAM-and-util-linux.patch
  0003-Add-Arch-Linux-defaults-for-login.defs.patch
  shadow.{timer,service}
  shadow.{sysusers,tmpfiles}
  useradd.defaults
)
sha512sums=('5912ece0231be61633e6db9c4156424c5fcc3f8da071ae949dd810ca5e3f6d97c905f675659f2c4f1d63c12ab748529a6ff966d8f450dab6be28d33c079d83a7'
            '03e3f45dd222dd3b37d84024af53dbbed9c59758d87f1d891111b7d87b32efa9ae38d9b59d45ba1f6393e971a8f89049b8b9ee17ed6d97725cf18e28589ee17b'
            '1299a1c5f1a81782085ed7593f10b08f314e8d2ff14c457772a929d5db6bf84160b3568cb13d9c7251035cdfade58a51b6e2f63da51bcaff586493c83052bb2d'
            '8a51426d756b0e188992d724b73a495b6da05b3a469f182d7a26a55b1d4c6c368018530e190146e0e9e7f8e59ffb2b0bb50ac9478492db049d1a4c8b6a8f30f6'
            'e4edf705dd04e088c6b561713eaa1afeb92f42ac13722bff037aede6ac5ad7d4d00828cfb677f7b1ff048db8b6788238c1ab6a71dfcfd3e02ef6cb78ae09a621'
            '2c8689b52029f6aa27d75b8b05b0b36e2fc322cab40fdfbb50cdbe331f61bc84e8db20f012cf9af3de8c4e7fdb10c2d5a4925ca1ba3b70eb5627772b94da84b3'
            '5afac4a96b599b0b8ed7be751e7160037c3beb191629928c6520bfd3f2adcd1c55c31029c92c2ff8543e6cd9e37e2cd515ba4e1789c6d66f9c93b4e7f209ee7a'
            '97a6a57c07502e02669dc1a91bffc447dba7d98d208b798d80e07de0d2fdf9d23264453978d2d3d1ba6652ca1f2e22cdadc4309c7b311e83fa71b00ad144f877'
            '706ba6e7fa8298475f2605a28daffef421c9fa8d269cbd5cbcf7f7cb795b40a24d52c20e8d0b73e29e6cd35cd7226b3e9738dc513703e87dde04c1d24087a69c')
b2sums=('e895e02d43734449d0e17788df51ba55eb92b29ea58b19b1b1b0d3cd0011afab6d7a7ac7a35d65cd2db4138305ea7c9e63f809add7f852431e6640a477fcbf78'
        'db105b2db1e53ec8b441028a03102181dc9df4b2d329c2688d15ec070e5b63d5077ab0a8e339e73402f4f2dd0b9af0dc9116589be95d4b82b820a8a632e9639e'
        '48f0fad2ceb08bf47d35419ef292d76cb92a0f823e4f5cf2eb99a371ba95cfa2f85e4539f4f05437ba2b5400f4ab0fecbefc9c6de2568bda8e531876e886e15c'
        '98c7ef4c9e0f2383615972c2b4fc74414b6427510dfd0b5d4da50a0efcbed94081ddb7805aedb707db39eaea8415c28a8b8b0b0eb874d8d906ed4e8cbf6f12c5'
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

  cd "${pkgname/-selinux}"
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
    --without-bcrypt
    --without-libbsd  # shadow can use internal implementation for getting passphrase
    --without-nscd  # we do not ship nscd anymore
    --with-selinux
    --without-su  # su is provided by util-linux
  )

  cd "${pkgname/-selinux}"
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

  cd "${pkgname/-selinux}"

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
