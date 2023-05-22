#!/usr/bin/env python3
# -*- coding:UTF-8 -*
# Copyright (c) 2014-2023 Nicolas Iooss
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
import re
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

logger = logging.getLogger(__name__)

# Path configuration
CURRENT_DIR = Path(__file__).parent
BASE_PACKAGES_DIR = CURRENT_DIR / "base-noselinux"
SELINUX_PACKAGES_DIR = CURRENT_DIR
BASE_PKGLIST_FILE = CURRENT_DIR / "base_pkglist.txt"
PACMAN_DB_DIR = CURRENT_DIR / ".pacman-db"
PACMAN_CONF_FILE = CURRENT_DIR / "local-pacman.conf"

ARCH_GITLOG_URL = "https://gitlab.archlinux.org/archlinux/packaging/packages/{}/-/commits/main"
ARCH_GITREMOTE = "https://gitlab.archlinux.org/archlinux/packaging/packages/{}.git"


def sync_local_pacman_db() -> bool:
    """Sync PACMAN_DB_DIR to get the latest available package versions"""
    logger.info(f"Synchronizing package databases in {PACMAN_DB_DIR}")
    PACMAN_DB_DIR.mkdir(exist_ok=True, parents=True)

    # This command comes from "checkupdates" script from pacman package
    cmd = [
        "fakeroot",
        "pacman",
        "-Sy",
        "--config",
        str(PACMAN_CONF_FILE),
        "--dbpath",
        str(PACMAN_DB_DIR),
        "--logfile",
        "/dev/null",
    ]
    p = subprocess.Popen(cmd)
    retval = p.wait()
    if retval:
        logger.error(f"pacman exited with code {retval}")
        return False
    return True


def get_pkgbuild_pkgver(pkgbuild_filepath: Path) -> Optional[Tuple[str, int]]:
    """Get the version of a package from its PKGBUILD"""
    pkgver = None
    pkgrel = None
    pkgmajor_value = None
    realver_value = None
    with pkgbuild_filepath.open("r") as fd:
        for line in fd:
            matches = re.match(r"^pkgver=([0-9a-zA-Z.-]+)\s*$", line)
            if matches is not None:
                pkgver = matches.group(1)
                continue

            # linux package defines _srcver
            matches = re.match(r"^_srcver=([0-9a-zA-Z.-]+)\s*$", line)
            if matches is not None:
                pkgver = matches.group(1).replace("-", ".")
                continue

            # sudo package defines _sudover
            matches = re.match(r"^_sudover=([0-9a-zA-Z.-]+)(p[0-9]+)\s*$", line)
            if matches is not None:
                pkgver = ".".join(matches.groups())
                continue
            matches = re.match(r"^_sudover=([0-9a-zA-Z.-]+)\s$", line)
            if matches is not None:
                pkgver = matches.group(1)
                continue

            # systemd package defines _tag_name
            matches = re.match(r"^_tag_name=([0-9.]+)\s$", line)
            if matches is not None:
                pkgver = matches.group(1)
                continue

            # util-linux package defines _pkgmajor and _realver
            matches = re.match(r"^_pkgmajor=([0-9a-zA-Z.-]+)\s*$", line)
            if matches is not None:
                pkgmajor_value = matches.group(1)
                continue
            if pkgmajor_value is not None:
                matches = re.match(r"^_realver=\$\{_pkgmajor\}([0-9a-zA-Z.-]*)$", line)
                if matches is not None:
                    realver_value = pkgmajor_value + matches.group(1)
                    continue
            if realver_value is not None:
                matches = re.match(r"^pkgver=\${_realver/-/}([0-9a-zA-Z.-]*)\s*$", line)
                if matches is not None:
                    pkgver = realver_value.replace("-", "") + matches.group(1)
                    continue

            # Retrieve pkgrel
            matches = re.match(r"^pkgrel=([0-9]+)\s*$", line)
            if matches is not None:
                pkgrel = int(matches.group(1))
                continue
    if pkgver is None:
        logger.error(f"No pkgver definition found in {pkgbuild_filepath}")
        return None
    elif pkgrel is None:
        logger.warning(f"No pkgrel definition found in {pkgbuild_filepath}")
        return None
    return pkgver, pkgrel


class Package:
    """A base package which has an -selinux equivalent"""

    def __init__(self, basepkgname: str, basepkgver: Optional[str], basepkgrel: int, repo: str) -> None:
        if basepkgver is None:
            assert basepkgrel == 0
        self.basepkgname = basepkgname
        self.basepkgver = basepkgver
        self.basepkgrel = basepkgrel
        self.repo = repo

    def get_pacman_pkgver(self, use_system_db: bool = False) -> Optional[Tuple[str, int]]:
        """Get the latest version of the base package"""
        cmd = ["pacman", "-Si", self.basepkgname]
        if not use_system_db:
            cmd += ["--dbpath", str(PACMAN_DB_DIR)]
        p = subprocess.Popen(cmd, env={"LANG": "C"}, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        assert p.stdout is not None
        for line in p.stdout:
            sline = line.decode("ascii", errors="ignore").strip()
            matches = re.match(r"^Version\s*:\s*([0-9a-z.-]+)-([0-9]+)\s*$", sline, re.I)
            if matches is not None:
                return matches.group(1), int(matches.group(2))
        retval = p.wait()
        if retval:
            errmsg = p.communicate()[1].decode("ascii", errors="ignore").strip()
            logger.error(f"pacman error {retval}: {errmsg}")
        else:
            logger.error(f"Unable to find package version for {self.basepkgname}")
        return None

    def download_pkgsrc(self) -> bool:
        """Download the source package into basedir/pkgname directory

        Don't use ABS (through rsync or yaourt -G) because it is only updated
        once per day and appears to be late on the Git tree.
        """
        BASE_PACKAGES_DIR.mkdir(exist_ok=True, parents=True)

        logger.info(f"Getting the source package of {self.basepkgname}")
        git_dirname = self.basepkgname
        proc = subprocess.Popen(
            [
                "git",
                "clone",
                "--branch",
                "main",
                "--single-branch",
                "--depth",
                "1",
                ARCH_GITREMOTE.format(self.basepkgname),
                git_dirname,
            ],
            cwd=BASE_PACKAGES_DIR,
        )
        retval = proc.wait()
        if retval:
            logger.error(f"git clone exited with code {retval}")
            return False
        return True

    def compare_package(self, use_system_db: bool = False) -> bool:
        """Compare a base package with its -selinux equivalent"""
        # Path to the downloaded PKGBUILD of the base package
        path_base = BASE_PACKAGES_DIR / self.basepkgname
        pkgbuild_base = path_base / "PKGBUILD"

        # Path to the PKGBUILD of the -selinux package
        selinuxpkgname = self.basepkgname + "-selinux"
        path_selinux = SELINUX_PACKAGES_DIR / selinuxpkgname
        pkgbuild_selinux = path_selinux / "PKGBUILD"

        if not path_selinux.exists():
            logger.error(f"SELinux package directory doesn't exist ({path_selinux})")
            return False

        if not pkgbuild_selinux.exists():
            logger.error(f"PKGBUILD for {selinuxpkgname} doesn't exist ({pkgbuild_selinux})")
            return False

        # Get current version of the SElinux package, to validate the base version
        pkgver_selinux = get_pkgbuild_pkgver(pkgbuild_selinux)
        if pkgver_selinux is None:
            logger.error(f"Failed to get the package version of {selinuxpkgname}")
            return False
        if self.basepkgver is None:
            # Use the PKGBUILD version to know which base package is synced
            self.basepkgver, self.basepkgrel = pkgver_selinux
        elif pkgver_selinux[0] != self.basepkgver:
            logger.error(
                f"{BASE_PKGLIST_FILE} is out of sync: package {selinuxpkgname} has version {pkgver_selinux[0]} in its PKGBUILD but {self.basepkgver} in the list"  # noqa
            )
            logger.error(
                f"You need to update {BASE_PKGLIST_FILE} for example with '{self.repo}/{self.basepkgname} = {pkgver_selinux[0]}-1'"  # noqa
            )
            return False
        del pkgver_selinux

        # Get latest version of the base package
        pkgver_base = self.get_pacman_pkgver(use_system_db)
        if pkgver_base is None:
            logger.error(f"Failed to get the package version of {self.basepkgname} with pacman")
            return False

        if pkgver_base == (self.basepkgver, self.basepkgrel):
            logger.info(f"Package {selinuxpkgname} is up to date (version {pkgver_base[0]}-{pkgver_base[1]})")
            return True

        logger.info(
            f"Package {selinuxpkgname} needs an update from {self.basepkgver}-{self.basepkgrel} to {pkgver_base[0]}-{pkgver_base[1]}"  # noqa
        )

        # Download the PKGBUILD of the base package, if needed
        if not pkgbuild_base.exists():
            if path_base.exists():
                logger.error(f"PKGBUILD for {self.basepkgname} has been deleted. Please remove {path_base}")
                return False
            if not self.download_pkgsrc():
                return False

        if not pkgbuild_base.exists():
            logger.error(f"git clone hasn't created {pkgbuild_base}")
            return False

        pkgver_base2 = get_pkgbuild_pkgver(pkgbuild_base)
        if pkgver_base2 is None:
            logger.error(f"Failed to parse the package version of {pkgbuild_base}")
            return False
        if pkgver_base > pkgver_base2:
            logger.error(f"PKGBUILD for {self.basepkgname} is out of date. Please remove {path_base}")
            return False
        if pkgver_base < pkgver_base2:
            logger.warning(f"Downloaded PKGBUILD for {self.basepkgname} is in testing. Beware!")

        logger.info(f"You can now compare {path_selinux} and {path_base} to update the SELinux package")
        logger.info(f"... git log of Arch package : {ARCH_GITLOG_URL.format(self.basepkgname)}")
        return True


def load_package_baselist(filename: Optional[Path] = None) -> Dict[str, Package]:
    """Load a list of Arch Linux packages with versions"""
    if filename is None:
        filename = BASE_PKGLIST_FILE
    baselist = {}
    with filename.open("r") as fd:
        for linenum, line in enumerate(fd):
            # Remove comments
            line = line.split(";", 1)[0]
            line = line.split("#", 1)[0]
            line = line.strip().lower()
            if not line:
                continue
            matches = re.match(r"^([-_a-z0-9]+)/([-_a-z0-9]+)\s*=\s*([-.0-9a-z]+)-([0-9]+)$", line)
            if matches is not None:
                repo, pkgname, pkgver, pkgrel = matches.groups()
            else:
                matches = re.match(r"^([-_a-z0-9]+)/([-_a-z0-9]+)", line)
                if matches is not None:
                    repo, pkgname = matches.groups()
                    pkgver = None
                    pkgrel = 0
                else:
                    logger.warning(f"Ignoring line {linenum}, not in format 'repo/pkgname = pkgver-pkgrel'")
                    continue
            if pkgname in baselist:
                logger.warning(f"Duplicate definition of package {pkgname}")
                continue
            baselist[pkgname] = Package(pkgname, pkgver, int(pkgrel), repo)
    return baselist


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Compare Arch Linux packages with the -selinux ones")
    parser.add_argument(
        "-s",
        "--system-db",
        action="store_true",
        help=f"use pacman system DB to get package versions instead of '{PACMAN_DB_DIR.name}' local directory",
    )
    args = parser.parse_args(argv)

    if not args.system_db:
        if not sync_local_pacman_db():
            return 1

    baselist = load_package_baselist()
    for pkgname in sorted(baselist.keys()):
        if not baselist[pkgname].compare_package(use_system_db=args.system_db):
            return 1
    return 0


if __name__ == "__main__":
    logging.basicConfig(format="[%(levelname)s] %(message)s", level=logging.DEBUG)
    sys.exit(main())
