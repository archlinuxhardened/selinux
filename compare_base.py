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
import shutil
import subprocess
import sys


logger = logging.getLogger(__name__)

# Path configuration
CURRENT_DIR = os.path.dirname(__file__)
BASE_PACKAGES_DIR = os.path.join(CURRENT_DIR, 'base-noselinux')
SELINUX_PACKAGES_DIR = CURRENT_DIR
BASE_PKGLIST_FILE = os.path.join(CURRENT_DIR, 'base_pkglist.txt')
PACMAN_DB_DIR = os.path.join(CURRENT_DIR, '.pacman-db')
PACMAN_CONF_FILE = os.path.join(CURRENT_DIR, 'local-pacman.conf')

ARCH_GITLOG_URL = 'https://github.com/archlinux/svntogit-packages/commits/packages/{}/trunk'
ARCH_GITREMOTE = 'https://github.com/archlinux/svntogit-packages.git'


def sync_local_pacman_db():
    """Sync PACMAN_DB_DIR to get the latest available package versions"""
    logger.info("Synchronizing package databases in {}".format(PACMAN_DB_DIR))

    if not os.path.exists(PACMAN_DB_DIR):
        os.makedirs(PACMAN_DB_DIR)

    # This command comes from "checkupdates" script from pacman package
    cmd = [
        'fakeroot', 'pacman', '-Sy',
        '--config', PACMAN_CONF_FILE,
        '--dbpath', PACMAN_DB_DIR,
        '--logfile', '/dev/null',
    ]
    p = subprocess.Popen(cmd)
    retval = p.wait()
    if retval:
        logger.error("pacman exited with code {}".format(retval))
        return False
    return True


def get_pkgbuild_pkgver(pkgbuild_filepath):
    """Get the version of a package from its PKGBUILD"""
    pkgver = None
    pkgrel = None
    pkgmajor_value = None
    realver_value = None
    with open(pkgbuild_filepath, 'r') as fd:
        for line in fd:
            matches = re.match(r'^pkgver=([0-9a-zA-Z-.]+)\s*$', line)
            if matches is not None:
                pkgver = matches.group(1)
                continue

            # linux package defines _srcver
            matches = re.match(r'^_srcver=([0-9a-zA-Z-.]+)\s*$', line)
            if matches is not None:
                pkgver = matches.group(1).replace('-', '.')
                continue

            # sudo package defines _sudover
            matches = re.match(r'^_sudover=([0-9a-zA-Z-.]+)(p[0-9]+)\s*$', line)
            if matches is not None:
                pkgver = '.'.join(matches.groups())
                continue
            matches = re.match(r'^_sudover=([0-9a-zA-Z-.]+)\s$', line)
            if matches is not None:
                pkgver = matches.group(1)
                continue

            # systemd package defines _tag_name
            matches = re.match(r'^_tag_name=([0-9.]+)\s$', line)
            if matches is not None:
                pkgver = matches.group(1)
                continue

            # util-linux package defines _pkgmajor and _realver
            matches = re.match(r'^_pkgmajor=([0-9a-zA-Z-.]+)\s*$', line)
            if matches is not None:
                pkgmajor_value = matches.group(1)
                continue
            if pkgmajor_value is not None:
                if line == '_realver=${_pkgmajor}\n':
                    realver_value = pkgmajor_value
                    continue
            if realver_value is not None:
                matches = re.match(r'^pkgver=\${_realver/-/}([0-9a-zA-Z-.]*)\s*$', line)
                if matches is not None:
                    pkgver = realver_value.replace('-', '') + matches.group(1)
                    continue

            # Retrieve pkgrel
            matches = re.match(r'^pkgrel=([0-9]+)\s*$', line)
            if matches is not None:
                pkgrel = int(matches.group(1))
                continue
    if pkgver is None:
        logger.error("No pkgver definition found in {}".format(pkgbuild_filepath))
    elif pkgrel is None:
        logger.warning("No pkgrel definition found in {}".format(pkgbuild_filepath))
    return pkgver, pkgrel


class Package(object):
    """A base package which has an -selinux equivalent"""
    def __init__(self, basepkgname, basepkgver, basepkgrel, repo):
        self.basepkgname = basepkgname
        self.basepkgver = basepkgver
        self.basepkgrel = basepkgrel
        self.repo = repo

    def get_pacman_pkgver(self, use_system_db=False):
        """Get the latest version of the base package"""
        cmd = ['pacman', '-Si', self.basepkgname]
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
            logger.error("Unable to find package version for {}".format(self.basepkgname))
        return

    def download_pkgsrc(self):
        """Download the source package into basedir/pkgname directory

        Don't use ABS (through rsync or yaourt -G) because it is only updated
        once per day and appears to be late on the Git tree.
        """
        if not os.path.exists(BASE_PACKAGES_DIR):
            os.makedirs(BASE_PACKAGES_DIR)
            if not os.path.exists(BASE_PACKAGES_DIR):
                logger.error("Unable to create {}".format(BASE_PACKAGES_DIR))
                return False

        logger.info("Getting the source package of {}".format(self.basepkgname))
        git_dirname = 'gitclone-{}'.format(self.basepkgname)
        proc = subprocess.Popen(
            [
                'git', 'clone',
                '--branch', 'packages/{}'.format(self.basepkgname),
                '--single-branch', '--depth', '1', ARCH_GITREMOTE, git_dirname],
            cwd=BASE_PACKAGES_DIR)
        retval = proc.wait()
        if retval:
            logger.error("git clone exited with code {}".format(retval))
            return False
        for arch in ('x86_64', 'any'):
            srcpath = os.path.join(BASE_PACKAGES_DIR, git_dirname, 'repos', self.repo + '-' + arch)
            if os.path.exists(srcpath):
                shutil.move(srcpath, os.path.join(BASE_PACKAGES_DIR, self.basepkgname))
                shutil.rmtree(os.path.join(BASE_PACKAGES_DIR, git_dirname))
                return True

        logger.error("Unable to find repos/{}-$ARCH in source package".format(self.repo))
        return False

    def compare_package(self, use_system_db=False):
        """Compare a base package with its -selinux equivalent"""
        # Path to the downloaded PKGBUILD of the base package
        path_base = os.path.join(BASE_PACKAGES_DIR, self.basepkgname)
        pkgbuild_base = os.path.join(path_base, 'PKGBUILD')

        # Path to the PKGBUILD of the -selinux package
        selinuxpkgname = self.basepkgname + '-selinux'
        path_selinux = os.path.join(SELINUX_PACKAGES_DIR, selinuxpkgname)
        pkgbuild_selinux = os.path.join(path_selinux, 'PKGBUILD')

        if not os.path.exists(path_selinux):
            logger.error("SELinux package directory doesn't exist ({})".format(path_selinux))
            return False

        if not os.path.exists(pkgbuild_selinux):
            logger.error("PKGBUILD for {} doesn't exist ({})".format(selinuxpkgname, pkgbuild_selinux))
            return False

        # Get current version of the SElinux package, to validate the base version
        pkgver_selinux = get_pkgbuild_pkgver(pkgbuild_selinux)
        if pkgver_selinux is None:
            logger.error("Failed to get the package version of {}".format(selinuxpkgname))
            return False
        if self.basepkgver is None:
            # Use the PKGBUILD version to know which base package is synced
            self.basepkgver, self.basepkgrel = pkgver_selinux
        elif pkgver_selinux[0] != self.basepkgver:
            logger.error("{} is out of sync: package {} has version {} in its PKGBUILD but {} in the list".format(
                BASE_PKGLIST_FILE, selinuxpkgname, pkgver_selinux[0], self.basepkgver))
            logger.error("You need to update {} for example with '{}/{} = {}-1'".format(
                BASE_PKGLIST_FILE, self.repo, self.basepkgname, pkgver_selinux[0]))
            return False
        del pkgver_selinux

        # Get latest version of the base package
        pkgver_base = self.get_pacman_pkgver(use_system_db)
        if pkgver_base is None:
            logger.error("Failed to get the package version of {} with pacman".format(self.basepkgname))
            return False

        if pkgver_base == (self.basepkgver, self.basepkgrel):
            logger.info("Package {0} is up to date (version {1[0]}-{1[1]})".format(
                selinuxpkgname, pkgver_base))
            return True

        logger.info("Package {0} needs an update from {1}-{2} to {3[0]}-{3[1]}".format(
            selinuxpkgname, self.basepkgver, self.basepkgrel, pkgver_base))

        # Download the PKGBUILD of the base package, if needed
        if not os.path.exists(pkgbuild_base):
            if os.path.exists(path_base):
                logger.error("PKGBUILD for {} has been deleted. Please remove {}".format(
                    self.basepkgname, path_base))
                return False
            if not self.download_pkgsrc():
                return False

        if not os.path.exists(pkgbuild_base):
            logger.error("yaourt hasn't created {}".format(pkgbuild_base))
            return False

        pkgver_base2 = get_pkgbuild_pkgver(pkgbuild_base)
        if pkgver_base > pkgver_base2:
            logger.error("PKGBUILD for {} is out of date. Please remove {}".format(self.basepkgname, path_base))
            return False
        elif pkgver_base < pkgver_base2:
            logger.warning("Downloaded PKGBUILD for {} is in testing. Beware!".format(self.basepkgname))

        logger.info("You can now compare {} and {} to update the SELinux package".format(path_selinux, path_base))
        logger.info("... git log of Arch package : {}".format(ARCH_GITLOG_URL.format(self.basepkgname)))
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
            matches = re.match(
                r'^([-_a-z0-9]+)/([-_a-z0-9]+)\s*=\s*([-.0-9a-z]+)-([0-9]+)$',
                line)
            if matches is not None:
                repo, pkgname, pkgver, pkgrel = matches.groups()
            else:
                matches = re.match(r'^([-_a-z0-9]+)/([-_a-z0-9]+)', line)
                if matches is not None:
                    repo, pkgname = matches.groups()
                    pkgver = None
                    pkgrel = 0
                else:
                    logger.warning("Ignoring line {}, not in format 'repo/pkgname = pkgver-pkgrel'".format(linenum))
                    continue
            if pkgname in baselist:
                logger.warning("Duplicate definition of package {}".format(pkgname))
                continue
            baselist[pkgname] = Package(pkgname, pkgver, int(pkgrel), repo)
    return baselist


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
        if not baselist[pkgname].compare_package(use_system_db=args.system_db):
            return 1
    return 0


if __name__ == '__main__':
    logging.basicConfig(
        format='[%(levelname)s] %(message)s',
        level=logging.DEBUG)
    sys.exit(main())
