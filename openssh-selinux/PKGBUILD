# Maintainer: David Runge <dvzrv@archlinux.org>
# Maintainer: Levente Polyak <anthraxx[at]archlinux[dot]org>
# Maintainer: Giancarlo Razzolini <grazzolini@archlinux.org>
# Contributor: Gaetan Bisson <bisson@archlinux.org>
# Contributor: Aaron Griffin <aaron@archlinux.org>
# Contributor: judd <jvinet@zeroflux.org>
# SELinux Maintainer: Nicolas Iooss (nicolas <dot> iooss <at> m4x <dot> org)
# SELinux Contributor: Timothée Ravier <tim@siosm.fr>
# SELinux Contributor: Nicky726 <Nicky726@gmail.com>
#
# This PKGBUILD is maintained on https://github.com/archlinuxhardened/selinux.
# If you want to help keep it up to date, please open a Pull Request there.

pkgname=openssh-selinux
pkgver=9.8p1
pkgrel=2
pkgdesc="SSH protocol implementation for remote login, command execution and file transfer, with SELinux support"
arch=(x86_64 aarch64)
url='https://www.openssh.com/portable.html'
license=(
  BSD-2-Clause
  BSD-3-Clause
  ISC
  LicenseRef-Public-Domain
  MIT
)
depends=(
  glibc
  libselinux
)
makedepends=(
  krb5
  libedit
  libfido2
  libxcrypt
  linux-headers
  openssl
  pam
  zlib
)
optdepends=(
  'libfido2: FIDO/U2F support'
  'sh: for ssh-copy-id and findssl.sh'
  'x11-ssh-askpass: input passphrase in X'
  'xorg-xauth: X11 forwarding'
)
backup=(
  etc/pam.d/sshd
  etc/ssh/ssh_config
  etc/ssh/sshd_config
)
conflicts=("${pkgname/-selinux}" "selinux-${pkgname/-selinux}")
provides=("${pkgname/-selinux}=${pkgver}-${pkgrel}"
          "selinux-${pkgname/-selinux}=${pkgver}-${pkgrel}")
groups=('selinux')
source=(
  https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/${pkgname/-selinux}-${pkgver}.tar.gz{,.asc}
  99-archlinux.conf
  ${pkgname/-selinux}.tmpfiles
  sshdgenkeys.service
  sshd.service
  ssh-agent.service
  sshd.pam
)
sha256sums=('dd8bd002a379b5d499dfb050dd1fa9af8029e80461f4bb6c523c49973f5a39f3'
            'SKIP'
            '78b806c38bc1e246daaa941bfe7880e6eb6f53f093bea5d5868525ae6d223d30'
            'fadd31c107aee3fc6b501ca046aeb5e6fb1b0256cc5cdcade4e2c95205823a28'
            'a76ffd6701768cfc2a2d3701dcc46d48ee1399ee51664746e61783c61c223ab1'
            '201af9f6e00700ebbfd3600c0025c022bff28f9bfd073e1a55756bfdf3bb2d5a'
            'fc70b23ec083a5fc45f37049ba7fa12164a800d83c701e852a8315d48a0ff13e'
            '633e24cbfcb045ba777d3e06d5f85dfaa06d44f4727d38c7fb2187c57498221d')
b2sums=('3bf983c4ef5358054ed0104cd51d3e0069fbc2b80d8522d0df644d5508ec1d26a67bf061b1b5698d1cdf0d2cbba16b4cdca12a4ce30da24429094576a075e192'
        'SKIP'
        '1ff8cd4ae22efed2b4260f1e518de919c4b290be4e0b5edbc8e2225ffe63788678d1961e6f863b85974c4697428ee827bcbabad371cfc91cc8b36eae9402eb97'
        '57e77e55fcbd9d7b9951adbafe11ba62e4b8b7338c2a6fe3f163afe5b84458db042024cefbc55f9393cf17d97d067f1c2d9c61880516501bfa4e5c92371e494a'
        'abae43979222b7c24452ee128df5c02e8a07a355e797824eedea6282eb4054a1a81686089d8a6a62416536435f8fa25bbb330d11b532877da526bbe8800692da'
        '6faea668a21c3f2c3e8cb973a55e53ccef6037a1d772d18e71d545b18bf63e7c9618f416c1b6e93672aadbdd9024408d41bfba69ddfe3d3ed9e42964130c968a'
        '12a02423bfdbe79f528ea06d70746362ea6aaaf07f28bb4a7efe707ace06429e86e4f5fe7758c3e865c20976faa614102b924725ea0e833690d3732e386fee33'
        '1d24cc029eccf71cee54dda84371cf9aa8d805433e751575ab237df654055dd869024b50facd8b73390717e63100c76bca28b493e0c8be9791c76a2e0d60990a')
validpgpkeys=('7168B983815A5EEF59A4ADFD2A3F414E736060BA')  # Damien Miller <djm@mindrot.org>

prepare() {
  cd ${pkgname/-selinux}-$pkgver
  # remove variable (but useless) first line in config (related to upstream VCS)
  sed '/^#.*\$.*\$$/d' -i ssh{,d}_config

  # prepend configuration option to include drop-in configuration files for sshd_config
  printf "# Include drop-in configurations\nInclude /etc/ssh/sshd_config.d/*.conf\n" | cat - sshd_config > sshd_config.tmp
  mv -v sshd_config.tmp sshd_config
  # prepend configuration option to include drop-in configuration files for ssh_config
  printf "# Include drop-in configurations\nInclude /etc/ssh/ssh_config.d/*.conf\n" | cat - ssh_config > ssh_config.tmp
  mv -v ssh_config.tmp ssh_config

  # extract separate licenses
  sed -n '89,113p' LICENCE > ../rijndael.Public-Domain.txt
  sed -n '116,145p' LICENCE > ../ssh.BSD-3-Clause.txt
  sed -n '148,209p' LICENCE > ../BSD-2-Clause.txt
  sed -n '213,218p' LICENCE > ../snprintf.Public-Domain.txt
  sed -n '222,258p' LICENCE > ../openbsd-compat.BSD-3-Clause.txt
  sed -n '260,278p' LICENCE > ../openbsd-compat.ISC.txt
  sed -n '280,308p' LICENCE > ../openbsd-compat.MIT.txt
  sed -n '280,308p' LICENCE > ../openbsd-compat.MIT.txt
  sed -n '310,338p' LICENCE > ../blowfish.BSD-3-Clause.txt
  sed -n '340,368p' LICENCE > ../replacement.BSD-2-Clause.txt
}

build() {
  local configure_options=(
    --prefix=/usr
    --sbindir=/usr/bin
    --libexecdir=/usr/lib/ssh
    --sysconfdir=/etc/ssh
    --disable-strip
    --with-libedit
    --with-security-key-builtin
    --with-ssl-engine
    --with-pam
    --with-privsep-user=nobody
    --with-privsep-path=/usr/share/empty.sshd
    --with-kerberos5=/usr
    --with-xauth=/usr/bin/xauth
    --with-pid-dir=/run
    --with-default-path='/usr/local/sbin:/usr/local/bin:/usr/bin'
    --without-zlib-version-check
    --with-selinux
  )

  cd ${pkgname/-selinux}-$pkgver

  ./configure "${configure_options[@]}"
  make
}

check() {
  # NOTE: make t-exec does not work in our build environment
  make file-tests interop-tests unit -C ${pkgname/-selinux}-$pkgver
}

package() {
  depends+=(
    krb5 libkrb5.so libgssapi_krb5.so
    libedit libedit.so
    libxcrypt libcrypt.so
    openssl libcrypto.so
    pam libpam.so
    zlib libz.so
  )

  cd ${pkgname/-selinux}-$pkgver

  make DESTDIR="$pkgdir" install

  install -vDm 644 ../99-archlinux.conf -t "$pkgdir/etc/ssh/sshd_config.d/"
  install -vdm 755 "$pkgdir/etc/ssh/ssh_config.d"

  install -Dm644 LICENCE -t "$pkgdir/usr/share/licenses/${pkgname/-selinux}/"
  install -Dm644 ../*.txt -t "$pkgdir/usr/share/licenses/${pkgname/-selinux}/"

  install -Dm644 ../sshdgenkeys.service -t "$pkgdir"/usr/lib/systemd/system/
  install -Dm644 ../sshd.service -t "$pkgdir"/usr/lib/systemd/system/
  install -Dm644 ../ssh-agent.service -t "$pkgdir"/usr/lib/systemd/user/
  install -Dm644 ../sshd.pam "$pkgdir"/etc/pam.d/sshd

  # factory files
  install -Dm644 ../sshd.pam "$pkgdir"/usr/share/factory/etc/pam.d/sshd
  install -Dm644 "$pkgdir/etc/ssh/moduli" -t "$pkgdir"/usr/share/factory/etc/ssh/
  install -Dm644 "$pkgdir/etc/ssh/ssh_config" -t "$pkgdir"/usr/share/factory/etc/ssh/
  install -Dm644 "$pkgdir/etc/ssh/sshd_config" -t "$pkgdir"/usr/share/factory/etc/ssh/
  install -vDm 644 ../99-archlinux.conf -t "$pkgdir/usr/share/factory/etc/ssh/sshd_config.d/"

  install -vDm 644 ../${pkgname/-selinux}.tmpfiles "$pkgdir/usr/lib/tmpfiles.d/${pkgname/-selinux}.conf"

  install -Dm755 contrib/findssl.sh -t "$pkgdir"/usr/bin/
  install -Dm755 contrib/ssh-copy-id -t "$pkgdir"/usr/bin/
  install -Dm644 contrib/ssh-copy-id.1 -t "$pkgdir"/usr/share/man/man1/
}

# vim: ts=2 sw=2 et:
