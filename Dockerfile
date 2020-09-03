# Usage:
#    sudo docker build -t arch-selinux-build .
#
# or with Podman on Arch Linux in July 2020:
#    podman --cgroup-manager=cgroupfs build -t arch-selinux-build .
#
# Once the container is build, you can get the packages in "pkgs" directory with:
#    sudo docker run -v "$(pwd)/pkgs:/packages" --rm -ti arch-selinux-build
# or
#    podman run -v "$(pwd)/pkgs:/packages" --rm -ti arch-selinux-build

# Use official Arch Linux Docker image (https://hub.docker.com/_/archlinux)
FROM archlinux:latest
LABEL Description="Build SELinux packages for Arch Linux"

COPY . /startdir

# * Install base packages which needed to build SELinux packages,
#   upgrading the system because mirrors remove older versions of package and
#   weird issues can occur for example when python or ruby is up to date but not
#   their dependencies (like libxcrypt, openssl, etc.).
# * Configure the system to be able to build packages as builduser, like makechrootpkg:
#   https://git.archlinux.org/devtools.git/tree/makechrootpkg.in?h=20200407#n155
# * Sync GPG keys used to verify package sources
# * Build and install every package, using /build as build directory
# * Remove temporary files
RUN \
    pacman -q --noconfirm -Syu base base-devel expect git && \
    pacman --noconfirm -Sc && \
    rm -rf /var/cache/pacman/pkg/* && \
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime && \
    useradd -g users -m builduser && \
    echo 'builduser ALL=(ALL) NOPASSWD: /usr/bin/pacman' >> /etc/sudoers && \
    echo 'builduser ALL=(ALL) NOPASSWD: /usr/bin/sh -c { pacman --noconfirm --ask=4 -U sudo-selinux/sudo-selinux-*.pkg.tar.zst && if test -e /etc/sudoers.pacsave ; then mv /etc/sudoers.pacsave /etc/sudoers ; fi }' >> /etc/sudoers && \
    echo 'MAKEFLAGS="-j$(nproc)"' >> /etc/makepkg.conf && \
    echo 'BUILDDIR=/build' >> /etc/makepkg.conf && \
    echo 'LOGDEST=/logdest' >> /etc/makepkg.conf && \
    mkdir /packages /build /logdest && \
    chown -R builduser /startdir /packages /build /logdest && \
    sudo -u builduser /startdir/clean.sh && \
    sudo -u builduser /startdir/recv_gpg_keys.sh && \
    sudo -u builduser /startdir/build_and_install_all.sh && \
    rm -rf /startdir/*/src/ /startdir/*/pkg/ && \
    pacman --noconfirm -Sc && rm -rf /var/cache/pacman/pkg/*

WORKDIR /startdir

# Copy packages to /packages when running, so that they can be easily exported.
CMD ["sh", "-c", "cp /startdir/*/*.pkg.tar.zst /packages"]
