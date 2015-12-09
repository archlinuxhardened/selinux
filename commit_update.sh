#!/bin/sh
# Commit local modifications to prepare the update of AUR packages

cd "$(dirname -- "$0")" || exit $?

# Run the given command after displaying it
log_and_run() {
    echo "Running: $*"
    "$@" || exit $?
}

# reset the git repository
log_and_run git reset HEAD

for DIR in $(find . -maxdepth 2 -name PKGBUILD -printf '%h\n' | sort)
do
    PKGNAME="${DIR##*/}"

    # Ignore directories without any change
    [ -n "$(git status --porcelain "$DIR")" ] || continue

    # Update .SRCINFO
    echo "Committing update to ${DIR#./} package"
    (cd "$DIR" && log_and_run mksrcinfo)

    # Commit everything with a custom commit message
    log_and_run git add "$DIR"
    PKGVER="$(sed -n 's/^\s*pkgver = \(.*\)$/\1/p' "$DIR/.SRCINFO" | head -n1)"
    PKGREL="$(sed -n 's/^\s*pkgrel = \(.*\)$/\1/p' "$DIR/.SRCINFO" | head -n1)"
    log_and_run git commit -m "$PKGNAME $PKGVER-$PKGREL update"
    tput bold
    echo "$PKGNAME changes has been commited. You can now push them to the AUR with:"
    echo "git subtree push --prefix=${DIR#./} aur-$PKGNAME master"
    tput sgr0
done
