#!/bin/bash
# Sync the .SRCINFO files with the PKGBUILDs

set -e

cd "$(dirname -- "$0")"

find . \( -name base-noselinux -prune \) -o -name PKGBUILD -printf '%h\n' | \
while read -r DIR
do
    echo "Generating $DIR/.SRCINFO"
    # As the header comment may differ (it contains a date and makepkg
    # version), compare without and update if other things differ.
    (cd "$DIR" && makepkg --printsrcinfo > .SRCINFO.new)
    if diff -q \
        <(sed -e '1,2{/^#/d}' "$DIR/.SRCINFO") \
        <(sed -e '1,2{/^#/d}' "$DIR/.SRCINFO.new")
    then
        rm "$DIR/.SRCINFO.new"
    else
        mv "$DIR/.SRCINFO.new" "$DIR/.SRCINFO"
    fi
done
