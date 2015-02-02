#!/bin/sh

set -e

pacman -S --noconfirm --needed ghc sudo

# habs
git clone https://github.com/archhaskell/habs /hinance-docker/habs
cd /hinance-docker/habs
git checkout $HABS_TAG
useradd -m user
chown -R user:user /hinance-docker/habs
sudo -iu user /hinance-docker/setup/setup-habs.sh
