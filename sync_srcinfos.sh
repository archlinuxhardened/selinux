#!/bin/bash
# Sync the .SRCINFO files with the PKGBUILDs

set -e

cd "$(dirname -- "$0")"

find . \( -name base-noselinux -prune \) -o \( -name .git -prune \) -o -name PKGBUILD -printf '%h\n' | sort | \
while read -r DIR
do
    echo "Generating $DIR/.SRCINFO"

    # For base-selinux and base-devel-selinux, updpkgsums does not work
    # (there is no sources)
    if [ "$DIR" = ./base-devel-selinux ] || [ "$DIR" = ./base-selinux ]
    then
        (cd "$DIR" && makepkg --printsrcinfo > .SRCINFO)
    else
        (cd "$DIR" && updpkgsums && makepkg --printsrcinfo > .SRCINFO)
    fi
done
