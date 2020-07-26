#!/bin/sh
# Clean all compiled packages and AUR source tarballs
# This does NOT clean downloaded files.  To find these files, you can use:
#    git ls-files --ignored --others --exclude-standard

# Ensure current directory is the top dir
cd "$(dirname -- "$0")"

rm -frv ./*/src/ ./*/pkg/
rm -fv ./*/*.pkg.tar.xz
rm -fv ./*/*.pkg.tar.xz.sig
rm -fv ./*/*.pkg.tar.zstd
rm -fv ./*/*.pkg.tar.zstd.sig
rm -fv ./*/*.src.tar.gz
rm -fv ./*/*.log

# Also clean the downloaded base PKGBUILDs
rm -frv base-noselinux/
