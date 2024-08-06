# Maintainer: Pierre Schmitz <pierre@archlinux.de>
# SELinux Maintainer: Nicolas Iooss (nicolas <dot> iooss <at> m4x <dot> org)
#
# This PKGBUILD is maintained on https://github.com/archlinuxhardened/selinux.
# If you want to help keep it up to date, please open a Pull Request there.

pkgname=logrotate-selinux
pkgver=3.22.0
pkgrel=1
pkgdesc="Rotates system logs automatically with SELinux support"
arch=('x86_64' 'aarch64')
url="https://github.com/logrotate/logrotate"
license=('GPL')
groups=('selinux')
depends=('popt' 'gzip' 'acl' 'libselinux')
conflicts=("${pkgname/-selinux}" "selinux-${pkgname/-selinux}")
provides=("${pkgname/-selinux}=${pkgver}-${pkgrel}"
          "selinux-${pkgname/-selinux}=${pkgver}-${pkgrel}")
backup=('etc/logrotate.conf')
source=("https://github.com/logrotate/logrotate/releases/download/${pkgver}/${pkgname/-selinux}-${pkgver}.tar.xz"{,.asc}
        'logrotate.conf')
sha256sums=('42b4080ee99c9fb6a7d12d8e787637d057a635194e25971997eebbe8d5e57618'
            'SKIP'
            '42e289081a4d6b144c89dbfc49bde7a01b383055bf90a05a764f8c3dee25a6ce')
validpgpkeys=('8ECCDF12100AD84DA2EE7EBFC78CE737A3C3E28E')

prepare() {
	cd "$srcdir/${pkgname/-selinux}-${pkgver}"

	echo '#!/bin/true' > test/test-0110.sh

	# Skip test-0112 to work around https://github.com/logrotate/logrotate/issues/632
	echo '#!/bin/true' > test/test-0112.sh
}

build() {
	cd "$srcdir/${pkgname/-selinux}-${pkgver}"

	./configure \
		--prefix=/usr \
		--sbindir=/usr/bin \
		--mandir=/usr/share/man \
		--with-compress-command=/usr/bin/gzip \
		--with-uncompress-command=/usr/bin/gunzip \
		--with-default-mail-command=/usr/bin/mail \
		--with-acl \
		--with-selinux
	make
}

check() {
	cd "$srcdir/${pkgname/-selinux}-${pkgver}"

	make test
}

package() {
	cd "$srcdir/${pkgname/-selinux}-${pkgver}"

	make DESTDIR="$pkgdir" install

	install -dm755 "$pkgdir/etc/logrotate.d"
	install -Dm644 "$srcdir/logrotate.conf" "$pkgdir/etc/logrotate.conf"

	install -D -m644 examples/logrotate.timer "${pkgdir}/usr/lib/systemd/system/logrotate.timer"
	install -D -m644 examples/logrotate.service "${pkgdir}/usr/lib/systemd/system/logrotate.service"
	install -d -m755 "$pkgdir/usr/lib/systemd/system/timers.target.wants"
	ln -s ../logrotate.timer "$pkgdir/usr/lib/systemd/system/timers.target.wants/logrotate.timer"
}
