#!/bin/sh
# Sync the .SRCINFO files with the PKGBUILDs

cd "$(dirname -- "$0")" || exit $?
find . -maxdepth 2 -name PKGBUILD -printf '%h\n' | \
while read DIR
do
    echo "Generating $DIR/.SRCINFO"
    mksrcinfo -o "$DIR/.SRCINFO" "$DIR/PKGBUILD"
done
