# Maintainer: Nicky726 (Nicky726 <at> gmail <dot> com)
# Contributor: Sergej Pupykin (pupykin <dot> s+arch <at> gmail <dot> com)

# needed to build checkpolicy tool. current flex have some problems...

pkgname=selinux-flex
_origname=flex
pkgver=2.5.4a
pkgrel=6
pkgdesc="A tool for generating text-scanning programs"
groups=('selinux' 'selinux-system-utilities')
arch=('i686' 'x86_64')
url="http://flex.sourceforge.net"
license=('custom')
depends=('glibc' 'bash' 'bison')
conflicts=("${_origname}")
provides=("${_origname}=2.5.4")
options=(!makeflags)
source=(http://downloads.sourceforge.net/sourceforge/${_origname}/${_origname}-${pkgver}.tar.bz2 \
        ${_origname}-arch.patch.gz)
md5sums=('c0b8e3dd63bce3f4a6543d845e17ce9a'
         '03f577be43792ff3df9c3ce5215b8e92')

build() {
  cd "${srcdir}/${_origname}-2.5.4"
  patch -Np1 <../${_origname}-arch.patch
  ./configure --prefix=/usr
  make
}

package() {
  cd "${srcdir}/${_origname}-2.5.4"
  make prefix=${pkgdir}/usr install
  cat > ${pkgdir}/usr/bin/lex << "EOF"
#!/bin/sh
# Begin /usr/bin/lex

exec /usr/bin/flex -l "$@"
# End /usr/bin/lex
EOF
  chmod 755 "${pkgdir}/usr/bin/lex"
  # install license
  install -D -m644 COPYING "${pkgdir}/usr/share/licenses/$pkgname/license.txt"
}
