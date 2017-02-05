# Usage: docker build -t arch-selinux-build .
# Once the container is build, you can get the packages in "pkgs" directory with:
#    docker run -v "$(pwd)/pkgs:/packages" --rm -ti arch-selinux-build

# Use Debian because Arch Linux has no official Docker image
FROM debian:sid
LABEL Description="Build SELinux packages for Arch Linux"

# Steps:
# - Install wget to be able to download and extract Arch Linux images
# - Download bootstrap image and extract it in /arch/root (cf. https://wiki.archlinux.org/index.php/Install_from_existing_Linux)
# - Switch over to Arch Linux, keeping Docker-special files
# - Configure the system to be able to build packages as user
# - Install base packages which needed to build SELinux packages
RUN \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get -qq update && \
    apt-get install -qqy gnupg wget && \
    apt-get clean && \
    gpg --keyserver hkp://pool.sks-keyservers.net. --recv-key 4AA4767BBC9C4B1D18AE28B77F2D434B9741E8AC && \
    mkdir /arch && cd /arch && \
    (wget -qO- https://mirror.rackspace.com/archlinux/iso/latest/sha1sums.txt | fgrep 'x86_64.tar' > sha1sum.txt) && \
    read -r SHA1 FILE < sha1sum.txt && \
    wget -q "https://mirror.rackspace.com/archlinux/iso/latest/$FILE" && \
    wget -q "https://mirror.rackspace.com/archlinux/iso/latest/$FILE.sig" && \
    gpg --verify "$FILE.sig" "$FILE" && \
    sha1sum -c sha1sum.txt && \
    tar -xpzf "$FILE" && \
    cd /arch/root.x86_64 && \
    rm -r /bin /lib* /opt /root /sbin /srv /usr /var && \
    LD_LIBRARY_PATH=/arch/root.x86_64/lib /arch/root.x86_64/lib/ld-linux-x86-64.so.* bin/mv bin lib* opt root sbin srv usr var / && \
    find /etc/* -maxdepth 0 -not \( -name resolv.conf -o -name hostname -o -name hosts \) -exec rm -r {} + && \
    rm /arch/root.x86_64/etc/hosts /arch/root.x86_64/etc/resolv.conf && \
    mv /arch/root.x86_64/etc/* /etc && \
    cd / && \
    rm -r /arch && \
    echo 'Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist && \
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime && \
    echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && \
    pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -q --noconfirm -Sy base base-devel expect git && \
    pacman --noconfirm -Sc && \
    rm -rf /var/cache/pacman/pkg/* && \
    useradd -g users -m user && \
    echo 'user ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    echo 'MAKEFLAGS="-j$(nproc)"' >> /etc/makepkg.conf

# Prepare a directory for the packages
RUN mkdir /packages

# Copy the PKGBUILDs in /build
COPY . /build
RUN chown -R user /build && sudo -u user /build/clean.sh

# Sync GPG keys used to verify package sources
RUN sudo -u user /build/recv_gpg_keys.sh

# Build and install every package, and remove temporary files
RUN \
    sudo -u user /build/build_and_install_all.sh && \
    rm -rf /build/*/src/ /build/*/pkg/ && \
    pacman --noconfirm -Sc && rm -rf /var/cache/pacman/pkg/*

WORKDIR /build

# Copy packages to /packages when running, so that they can be easily exported.
CMD ["sh", "-c", "cp /build/*/*.pkg.tar.xz /packages"]
