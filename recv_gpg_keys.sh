#!/bin/bash
# Receive every gpg keys used by packages

# GnuPG key server to use
GPG_KEYSRV="${GPG_KEYSRV:-hkps://hkps.pool.sks-keyservers.net}"

cd "$(dirname -- "$0")" || exit $?
for DIR in $(find . -maxdepth 2 -name PKGBUILD -printf '%h\n' | sort)
do
    validpgpkeys=()
    if ! source "$DIR/PKGBUILD" ; then
        echo >&2 "Failed to source $DIR/PKGBUILD"
        exit 1
    fi
    PKG="${DIR#./}"
    for GPGKEY in "${validpgpkeys[@]}" ; do
        if gpg --list-keys "$GPGKEY" > /dev/null 2>&1 ; then
            echo "$PKG: key $GPGKEY already received."
        else
            echo "$PKG: receiving key..."
            gpg --keyserver "$GPG_KEYSRV" --recv-keys "$GPGKEY" || exit $?
        fi
    done
done
