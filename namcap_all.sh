#!/bin/sh
# Run namcap on every package

for PKG_PKGBUILD in $(find . -maxdepth 2 -name PKGBUILD | sort)
do
    # Run namcap on PKGBUID files
    namcap "$PKG_PKGBUILD"

    # Run namcap on packages
    for PKG in $(find "$(dirname "$PKG_PKGBUILD")" -name '*.pkg.tar*' | sort)
    do
        if echo "$PKG" | grep -q '[-]debug-'
        then
            # debug packages do have dangling symlinks
            namcap -e symlink "$PKG"
        else
            namcap "$PKG"
        fi
    done
done
