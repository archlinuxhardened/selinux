#!/bin/sh
# Pull modifications from AUR git repositories using "git subtree merge"

cd "$(dirname -- "$0")" || exit $?

# Run the given command after displaying it
log_and_run() {
    tput bold
    echo "Running: $*"
    tput sgr0
    "$@"
}

# Be on master branch
log_and_run git checkout master || exit $?

for DIR in $(find . -maxdepth 2 -name PKGBUILD -printf '%h\n' | sort)
do
    PKGNAME="${DIR##*/}"

    # Create a remote for AUR if it does not exist
    REMOTE_NAME="aur-$PKGNAME"
    REMOTE_URL="https://aur.archlinux.org/$PKGNAME.git"
    REMOTE_PUSHURL="ssh+git://aur.archlinux.org/$PKGNAME.git"
    if ! (git remote show | grep -q "^$REMOTE_NAME\$")
    then
        log_and_run git remote add "$REMOTE_NAME" "$REMOTE_URL" || exit $?
        log_and_run git remote set-url --push "$REMOTE_NAME" "$REMOTE_PUSHURL" || exit $?
    fi
    log_and_run git fetch "$REMOTE_NAME" || exit $?

    # Merge the remote subtree and keep track of the commit number
    # Use "-c core.editor=true" to merge without editing the message
    OLDHEAD="$(git rev-parse HEAD)"
    log_and_run git -c core.editor=true subtree merge --prefix="${DIR#./}" "$REMOTE_NAME/master" || \
        exit $?
    NEWHEAD="$(git rev-parse HEAD)"
    PKGVER="$(sed -n 's/^\s*pkgver = \(.*\)$/\1/p' "$DIR/.SRCINFO" | head -n1)"
    PKGREL="$(sed -n 's/^\s*pkgrel = \(.*\)$/\1/p' "$DIR/.SRCINFO" | head -n1)"
    if [ "$OLDHEAD" != "$NEWHEAD" ]
    then
        # A merge commit has been created
        REMOTE_COMMIT="$(git rev-parse "$REMOTE_NAME/master")"
        git commit --date=now --amend --message \
"Merge $PKGNAME $PKGVER-$PKGREL update

Merge AUR commit $REMOTE_COMMIT:
https://aur.archlinux.org/cgit/aur.git/commit/?h=$PKGNAME&id=$REMOTE_COMMIT"
    fi
done
