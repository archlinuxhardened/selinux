#!/bin/bash
# Sync the .SRCINFO files with the PKGBUILDs

set -e

cd "$(dirname -- "$0")"

find . \( -name base-noselinux -prune \) -o -name PKGBUILD -printf '%h\n' | sort | \
while read -r DIR
do
    echo "Generating $DIR/.SRCINFO"
    (cd "$DIR" && makepkg --printsrcinfo > .SRCINFO)
done
