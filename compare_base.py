#!/usr/bin/env python
# -*- coding:UTF-8 -*
# Copyright (c) 2014 Nicolas Iooss
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
"""
Compare Arch Linux packages with the -selinux ones and find those needed
to be upgraded.

@author: Nicolas Iooss
@license: MIT
"""

import argparse
import logging
import os.path
import re
import subprocess
import sys


logger = logging.getLogger(__name__)

# Path configuration
CURRENT_DIR = os.path.dirname(__file__)
BASE_PACKAGES_DIR = os.path.join(CURRENT_DIR, 'base-noselinux')
SELINUX_PACKAGES_DIR = CURRENT_DIR
BASE_PKGLIST_FILE = os.path.join(CURRENT_DIR, 'base_pkglist.txt')
PACMAN_DB_DIR = os.path.join(CURRENT_DIR, '.pacman-db')

ARCH_GITLOG_URL = 'https://projects.archlinux.org/svntogit/packages.git/log/trunk?h=packages/{}'


def sync_local_pacman_db():
    """Sync PACMAN_DB_DIR to get the latest available package versions"""
    logger.info("Synchronizing package databases in {}".format(PACMAN_DB_DIR))

    if not os.path.exists(PACMAN_DB_DIR):
        os.makedirs(PACMAN_DB_DIR)

    # This command comes from "checkupdates" script from pacman package
    cmd = ['fakeroot', 'pacman', '-Sy', '--dbpath', PACMAN_DB_DIR, '--logfile', '/dev/null']
    p = subprocess.Popen(cmd)
    retval = p.wait()
    if retval:
        logger.error("pacman exited with code {}".format(retval))
        return False
    return True


def load_package_baselist(filename=None):
    """Load a list of Arch Linux packages with versions"""
    if filename is None:
        filename = BASE_PKGLIST_FILE
    baselist = {}
    with open(filename, 'r') as fd:
        for linenum, line in enumerate(fd):
            # Remove comments
            line = line.split(';', 1)[0]
            line = line.split('#', 1)[0]
            line = line.strip().lower()
            if not line:
                continue
            matches = re.match(r'^([-_a-z0-9]+)\s*=\s*([-.0-9a-z]+)-([0-9]+)$', line)
            if matches is None:
                logger.warn("Ignoring line {}, not in format 'pkgname = pkgver-pkgrel'".format(linenum))
                continue
            pkgname, pkgver, pkgrel = matches.groups()
            if pkgname in baselist:
                logger.warn("Duplicate definition of package {}".format(pkgname))
                continue
            baselist[pkgname] = (pkgver, int(pkgrel))
    return baselist


def get_pkgbuild_pkgver(pkgbuild_filepath):
    """Get the version of a package from its PKGBUILD"""
    pkgver = None
    pkgrel = None
    with open(pkgbuild_filepath, 'r') as fd:
        for line in fd:
            matches = re.match(r'^pkgver=([0-9a-zA-Z-.]+)\s*$', line)
            if matches is not None:
                pkgver = matches.group(1)
                continue

            # Sudo defines _sudover
            matches = re.match(r'^_sudover=([0-9a-zA-Z-.]+)(p[0-9]+)\s*$', line)
            if matches is not None:
                pkgver = '.'.join(matches.groups())
                continue

            # Retrieve pkgrel
            matches = re.match(r'^pkgrel=([0-9]+)\s*$', line)
            if matches is not None:
                pkgrel = int(matches.group(1))
                continue
    if pkgver is None:
        logger.error("No pkgver definition found in {}".format(pkgbuild_filepath))
    elif pkgrel is None:
        logger.warn("No pkgrel definition found in {}".format(pkgbuild_filepath))
    return pkgver, pkgrel


def get_pacman_pkgver(pkgname, use_system_db=False):
    """Get the latest version of a package"""
    cmd = ['pacman', '-Si', pkgname]
    if not use_system_db:
        cmd += ['--dbpath', PACMAN_DB_DIR]
    p = subprocess.Popen(
        cmd,
        env={'LANG': 'C'},
        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    for line in p.stdout:
        sline = line.decode('ascii', errors='ignore').strip()
        matches = re.match(r'^Version\s*:\s*([0-9a-z-.]+)-([0-9]+)\s*$', sline, re.I)
        if matches is not None:
            return matches.group(1), int(matches.group(2))
    retval = p.wait()
    if retval:
        errmsg = p.communicate()[1].decode('ascii', errors='ignore').strip()
        logger.error("pacman error {}: {}".format(retval, errmsg))
    else:
        logger.error("Unable to find package version for {}".format(pkgname))
    return


def compare_package(pkgname, pkgvertuple, use_system_db=False):
    """Compare a base package with its -selinux equivalent

    pkgname: name of the base package
    pkgvertuple: (pkgver, pkgrel) of the last version of the base package which
        was synced with the -selinux package
    """
    # Path to the downloaded PKGBUILD of the base package
    path_base = os.path.join(BASE_PACKAGES_DIR, pkgname)
    pkgbuild_base = os.path.join(path_base, 'PKGBUILD')

    # Path to the PKGBUILD of the -selinux package
    path_selinux = os.path.join(SELINUX_PACKAGES_DIR, pkgname + '-selinux')
    pkgbuild_selinux = os.path.join(path_selinux, 'PKGBUILD')

    if not os.path.exists(path_selinux):
        logger.error("SELinux package directory doesn't exist ({})".format(path_selinux))
        return False

    if not os.path.exists(pkgbuild_selinux):
        logger.error("PKGBUILD for {}-selinux doesn't exist ({})".format(pkgname, pkgbuild_selinux))
        return False

    # Get current version of the SElinux package, to validate pkgvertuple
    pkgver_selinux = get_pkgbuild_pkgver(pkgbuild_selinux)
    if pkgver_selinux is None:
        logger.error("Failed to get the package version of {}-selinux".format(pkgname))
        return False
    if pkgver_selinux[0] != pkgvertuple[0]:
        logger.error("{} is out of sync: package {}-selinux has version {} in its PKGBUILD but {} in the list".format(
            BASE_PKGLIST_FILE, pkgname, pkgver_selinux[0], pkgvertuple[0]))
        logger.error("You need to update {} for example with '{} = {}-1'".format(
            BASE_PKGLIST_FILE, pkgname, pkgver_selinux[0]))
        return False
    del pkgver_selinux

    # Get latest version of the base package
    pkgver_base = get_pacman_pkgver(pkgname, use_system_db)
    if pkgver_base is None:
        logger.error("Failed to get the package version of {} with pacman".format(pkgname))
        return False

    if pkgver_base == pkgvertuple:
        logger.info("Package {0}-selinux is up to date (version {1[0]}-{1[1]})".format(pkgname, pkgver_base))
        return True

    logger.info("Package {0}-selinux needs an update from {1[0]}-{1[1]} to {2[0]}-{2[1]}".format(
        pkgname, pkgvertuple, pkgver_base))

    # Download the PKGBUILD of the base package, if needed
    if not os.path.exists(pkgbuild_base):
        if os.path.exists(path_base):
            logger.error("PKGBUILD for {} has been deleted. Please remove {}".format(pkgname, path_base))
            return False
        if not os.path.exists(BASE_PACKAGES_DIR):
            os.makedirs(BASE_PACKAGES_DIR)
        logger.info("Running 'yaourt -G {}'".format(pkgname))
        p = subprocess.Popen(
            ['yaourt', '-G', pkgname],
            cwd=BASE_PACKAGES_DIR)
        retval = p.wait()
        if retval:
            logger.error("yaourt exited with code {}".format(retval))
            return False

    if not os.path.exists(pkgbuild_base):
        logger.error("yaourt hasn't created {}".format(pkgbuild_base))
        return False

    pkgver_base2 = get_pkgbuild_pkgver(pkgbuild_base)
    if pkgver_base > pkgver_base2:
        logger.error("PKGBUILD for {} is out of date. Please remove {}".format(pkgname, path_base))
        return False
    elif pkgver_base < pkgver_base2:
        logger.warn("Downloaded PKGBUILD for {} is in testing. Beware!".format(pkgname))

    logger.info("You can now compare {} and {} to update the SELinux package".format(path_selinux, path_base))
    logger.info("... git log of Arch package : {}".format(ARCH_GITLOG_URL.format(pkgname)))
    return True


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Compare Arch Linux packages with the -selinux ones")
    parser.add_argument(
        '-s', '--system-db', action='store_true',
        help="use pacman system DB to get package versions instead of '{}' local directory".format(
            os.path.basename(PACMAN_DB_DIR)))
    args = parser.parse_args(argv)

    if not args.system_db:
        if not sync_local_pacman_db():
            return 1

    baselist = load_package_baselist()
    for pkgname in sorted(baselist.keys()):
        if not compare_package(pkgname, baselist[pkgname], use_system_db=args.system_db):
            return 1
    return 0


if __name__ == '__main__':
    logging.basicConfig(
        format='[%(levelname)s] %(message)s',
        level=logging.DEBUG)
    sys.exit(main())
