#!/usr/bin/env bash
# Receive every gpg keys used by packages
set -eu
cd "$(dirname -- "$0")"

# Import all keys from the packages
gpg --import ./*/keys/pgp/*.asc

# Import all keys from the cache
gpg --import _pgp_cache/*.asc

# Download missing keys from a keyserver
# GnuPG key server to use
GPG_KEYSRV="${GPG_KEYSRV:-hkp://keys.gnupg.net}"

for DIR in $(find . -maxdepth 2 -name PKGBUILD -printf '%h\n' | sort)
do
    PKG="${DIR#./}"
    sed -n 's/^\s*validpgpkeys = //p' < "$DIR/.SRCINFO" | \
    while IFS= read -r GPGKEY ; do
        if gpg --list-keys "$GPGKEY" > /dev/null 2>&1 ; then
            echo "$PKG: key $GPGKEY found."
        else
            echo "$PKG: receiving key..."
            gpg --keyserver "$GPG_KEYSRV" --recv-keys "$GPGKEY"
        fi
    done
done
