# Maintainer: Nicolas Iooss (nicolas <dot> iooss <at> m4x <dot> org)
# Contributor: Nicky726 (Nicky726 <at> gmail <dot> com)
# Contributor: Simon Peter Nicholls (simon <at> mintsource <dot> org)
#
# This PKGBUILD is maintained on https://github.com/archlinuxhardened/selinux.
# If you want to help keep it up to date, please open a Pull Request there.

pkgname=selinux-refpolicy-arch
_reponame=selinux-policy-arch
_policyname=refpolicy-arch
pkgver=20250923
pkgrel=1
pkgdesc="Modular SELinux reference policy including headers and docs with Arch Linux patches"
arch=('any')
url="https://github.com/SELinuxProject/refpolicy/wiki"
license=('GPL2')
groups=('selinux')
makedepends=('git' 'python' 'checkpolicy>=3.0' 'semodule-utils')
depends=('policycoreutils>=3.0')
install="${pkgname}.install"
_commit=ecab6fc7bb576c45f93520b6f43b589d3730d5ab
source=("git+https://github.com/archlinuxhardened/${_reponame}#commit=${_commit}"
        'config')
sha256sums=('7d45a7623df6f0ef3536523879b7f4e9c7514a35f24aa8fb54bd67e0bfde7146'
            'c9f7cce9a06fd0595b3dd47d4fdde9d9c7457120c42c5f08bfdc5e89eb9a61df')

build() {
  cd "${srcdir}/${_reponame}"
  make bare
  make conf
  make
}

package() {
  cd "${srcdir}/${_reponame}"
  make DESTDIR="${pkgdir}" install
  make DESTDIR="${pkgdir}" install-headers
  make DESTDIR="${pkgdir}" PKGNAME="${_policyname}" install-docs

  # Create /var/lib/selinux, which is necessary for loading policy,
  # which is done via install script.
  install -d -m0755 "${pkgdir}/var/lib/selinux"

  # Install main SELinux config file besides /etc/selinux/config.
  # The install script will create a symlink.
  install -m644 -D "${srcdir}/config" "${pkgdir}/etc/selinux/config.${_policyname}"
}
