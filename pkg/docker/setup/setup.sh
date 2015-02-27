#!/bin/sh

set -e

# Arch Rollback Machine date.
ARM_YEAR=2014
ARM_MONTH=11
ARM_DAY=11

# Arch User Repository snapshot of 2014-11-11.
AUR_TAG=6c79797067afd7e029461cf54ff0773cb8b7189c

# Arch Haskell snapshot of 2014-11-11.
HABS_TAG=6dc782392572bc3f118b7af1f81fd8a7dc395e33

echo "Server = " \
     "http://seblu.net/a/arm/$ARM_YEAR/$ARM_MONTH/$ARM_DAY/\$repo/os/\$arch" \
     > /etc/pacman.d/mirrorlist
pacman -Syyuu --noconfirm

pacman -S --noconfirm --needed base base-devel cabal-install ghc git happy \
                               mupdf phantomjs python2-prettytable sudo

# aur
curl -O http://pkgbuild.com/git/aur-mirror.git/snapshot/aur-mirror-$AUR_TAG.tar.xz
tar -xJf aur-mirror-$AUR_TAG.tar.xz
mv aur-mirror-$AUR_TAG /hinance-docker/aur
rm aur-mirror-$AUR_TAG.tar.xz

# habs
git clone https://github.com/archhaskell/habs /hinance-docker/habs
cd /hinance-docker/habs
git checkout $HABS_TAG

# user
useradd -m user -G wheel
chmod +w /etc/sudoers
echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
chown -R user:user /hinance-docker

sudo -iu user /hinance-docker/setup/setup-pkgs.sh

paccache -rk0
rm -rf /hinance-docker/{aur,habs}
