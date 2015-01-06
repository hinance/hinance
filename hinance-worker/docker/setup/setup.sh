#!/bin/sh

set -e

APP="hinance-worker"

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

#
# Install official packages.
#

pacman -S --noconfirm --needed \
    base base-devel cabal-install firefox ghc git happy mupdf openssh \
    proxychains-ng python2-beautifulsoup3 python2-dateutil python2-feedparser \
    python2-flake8 python2-gdata python2-irc python2-lxml python2-mechanize \
    python2-pillow python2-requests python2-yaml xorg-server-xvfb

#
# AUR mirror
#

curl -O http://pkgbuild.com/git/aur-mirror.git/snapshot/aur-mirror-$AUR_TAG.tar.xz
tar -xJf aur-mirror-$AUR_TAG.tar.xz
mv aur-mirror-$AUR_TAG /setup/$APP/aur
rm aur-mirror-$AUR_TAG.tar.xz

#
# Install AUR packages.
#

# python2-html2text
cd /setup/$APP/aur/python2-html2text
makepkg -s --asroot --noconfirm
pacman -U --noconfirm python2-html2text-2014.9.25-2-any.pkg.tar.xz

# python2-selenium
# TODO: remove patch when the package is updated
cd /setup/$APP/aur/python2-selenium
patch PKGBUILD /setup/$APP/python2-selenium/PKGBUILD.patch
makepkg -s --asroot --noconfirm
pacman -U --noconfirm python2-selenium-2.43.0-1-x86_64.pkg.tar.xz

#
# Install Haskell stuff.
#

cabal update
cabal install pretty-show-1.6.8 regex-tdfa-1.2.0

#
# Removing unneeded stuff.
#

paccache -rk0

#
# Checking out Weboob repo.
#

mkdir -p /usr/share/$APP/weboob
git clone git://git.symlink.me/pub/oleg/weboob.git /usr/share/$APP/weboob
cd /usr/share/$APP/weboob
git checkout 16bb14d
