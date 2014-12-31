#!/bin/sh
# Compare packages with the AUR.
#
# This script retrieves the versions of packages in the current git tree and in
# the AUR and shows the differences between both:
# * If the versions are the same, display nothing.
# * If the package in the git tree is older than in the AUR, it is out of sync.
#   This happens when using an other outdated git branch or when the repo is
#   simply outdated.
# * If the package in the git tree is newer than in the AUR, this script invokes
#   the necessary commands to build the source package and display information
#   which is needed to upload the source package to the AUR.

# Ensure current directory is the top dir
cd "$(dirname "$0")"

# Keep a list of built source packages in $@
set -

# Enumerate every PKGBUILD
for PKGFILE in ./*/PKGBUILD
do
    PKGNAME="$(basename "${PKGFILE%/PKGBUILD}")"

    # Retrieve the versions from the PKGBUILD and from the AUR
    PKGVER="$(cd "$PKGNAME" && bash -c 'source ./PKGBUILD && echo $pkgver-$pkgrel')"
    if [ -z "$PKGVER" ]
    then
        echo >&2 "Unable to get version of package $PKGNAME from its PKGBUILD. Aborting."
        exit 1
    fi

    # Ignore release candicate packages (built for testing purposes)
    if [ "$PKGVER" != "${PKGVER/rc/}" ]
    then
        echo "Skip $PKGNAME with version $PKGVER."
        continue
    fi

    # Retrieve the version of the package from the AUR
    if [ -x /usr/bin/cower ]
    then
        AURVER="$(/usr/bin/cower --format=%v --info "$PKGNAME")"
    elif [ -x /usr/bin/yaourt ]
    then
        AURVER="$(LANG=C /usr/bin/yaourt -Si "$PKGNAME" | sed -n 's/^Version *: *//p')"
    else
        echo >&2 "No AUR download helper found. Please install cower or yaourt."
        exit 1
    fi
    if [ -z "$AURVER" ]
    then
        echo >&2 "Unable to get version of AUR package $PKGNAME."
        exit 1
    fi

    # Compare the versions
    case $(vercmp "$PKGVER" "$AURVER") in
        1)
            echo "AUR upload needed for $PKGNAME: $AURVER -> $PKGVER"
            echo "... web page: https://aur.archlinux.org/packages/$PKGNAME/"

            # Remove a previously build source package and create a new one
            PKGSRC="$PKGNAME/$PKGNAME-$PKGVER.src.tar.gz"
            rm -f "$PKGSRC"
            (cd "$PKGNAME" && makepkg --source)
            if ! [ -e "$PKGSRC" ]
            then
                echo "... failed to make a source package"
                continue
            fi
            set - "$@" "$PKGSRC"
            ;;
        -1)
            echo "Outdated package $PKGNAME: $PKGVER < $AURVER (AUR)"
            ;;
    esac
done

if [ "$#" -ge 1 ]
then
echo "Some source packages needs to be uploaded to the AUR. You can now run:"
    for PKGSRC in "$@"
    do
         echo "burp $PKGSRC"
    done
fi
