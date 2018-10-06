#!/bin/bash
# Export all the PGP keys used by packages in a cache directory

cd "$(dirname -- "$0")" || exit $?

mkdir -p _pgp_cache || exit $?

for DIR in $(find . -maxdepth 2 -name PKGBUILD -printf '%h\n' | sort)
do
    validpgpkeys=()
    if ! source "$DIR/PKGBUILD" ; then
        echo >&2 "Failed to source $DIR/PKGBUILD"
        exit 1
    fi
    PKG="${DIR#./}"
    for GPGKEY in "${validpgpkeys[@]}" ; do
        echo "$PKG: exporting key $GPGKEY"
        rm -f "_pgp_cache/$GPGKEY.asc"
        gpg --export --armor --output "_pgp_cache/$GPGKEY.asc" "$GPGKEY"
    done
done
