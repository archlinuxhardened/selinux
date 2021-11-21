#!/bin/bash
# Sync the .SRCINFO files with the PKGBUILDs

set -e

cd "$(dirname -- "$0")"

find . \( -name base-noselinux -prune \) -o \( -name .git -prune \) -o -name PKGBUILD -printf '%h\n' | sort | \
while read -r DIR
do
    echo "Generating $DIR/.SRCINFO"
    (cd "$DIR" && updpkgsums && makepkg --printsrcinfo > .SRCINFO)

    # For base-selinux and base-devel-selinux, updpkgsums introduces an blank
    # line at the end of the file. Delete it.
    if [ "$DIR" = ./base-devel-selinux ] || [ "$DIR" = ./base-selinux ]
    then
        sed '${/^$/d}' -i "$DIR/PKGBUILD"
    fi
done
