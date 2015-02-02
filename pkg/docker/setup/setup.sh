#!/bin/sh

set -e

# Arch Rollback Machine date.
ARM_YEAR=2014
ARM_MONTH=11
ARM_DAY=11

# Arch User Repository snapshot of 2014-11-11.
AUR_TAG=6c79797067afd7e029461cf54ff0773cb8b7189c

echo "Server = " \
     "http://seblu.net/a/arm/$ARM_YEAR/$ARM_MONTH/$ARM_DAY/\$repo/os/\$arch" \
     > /etc/pacman.d/mirrorlist
pacman -Syyuu --noconfirm

pacman -S --noconfirm --needed base base-devel firefox mupdf xorg-server-xvfb

curl -O http://pkgbuild.com/git/aur-mirror.git/snapshot/aur-mirror-$AUR_TAG.tar.xz
tar -xJf aur-mirror-$AUR_TAG.tar.xz
mv aur-mirror-$AUR_TAG /hinance-docker/aur
rm aur-mirror-$AUR_TAG.tar.xz

# python2-elementtidy
cd /hinance-docker/aur/python2-elementtidy
makepkg -s --asroot --noconfirm
pacman -U --noconfirm python2-elementtidy-1.0-1-x86_64.pkg.tar.xz

# python2-html2text
cd /hinance-docker/aur/python2-html2text
makepkg -s --asroot --noconfirm
pacman -U --noconfirm python2-html2text-2014.9.25-2-any.pkg.tar.xz

# python2-selenium
# TODO: remove this patch when the package is updated
cd /hinance-docker/aur/python2-selenium
patch PKGBUILD /hinance-docker/setup/python2-selenium/PKGBUILD.patch
makepkg -s --asroot --noconfirm
pacman -U --noconfirm python2-selenium-2.43.0-1-x86_64.pkg.tar.xz

# weboob-git
cd /hinance-docker/aur/weboob-git
patch PKGBUILD /hinance-docker/setup/weboob-git/PKGBUILD.patch
makepkg -s --asroot --noconfirm
pacman -U --noconfirm weboob-git-2402b546-1-x86_64.pkg.tar.xz

# leiningen
cd /hinance-docker/aur/leiningen
makepkg -s --asroot --noconfirm
pacman -U --noconfirm leiningen-1\:2.5.0-1-any.pkg.tar.xz
LEIN_ROOT=1 lein version

#
# Install Haskell stuff.
#

cabal update
cabal install pretty-show-1.6.8 regex-tdfa-1.2.0

paccache -rk0
rm -rf /hinance-docker/aur
