#!/bin/sh

set -e

# Arch User Repository snapshot of 2014-11-11.
AUR_TAG=6c79797067afd7e029461cf54ff0773cb8b7189c

# aur
curl -O http://pkgbuild.com/git/aur-mirror.git/snapshot/aur-mirror-$AUR_TAG.tar.xz
tar -xJf aur-mirror-$AUR_TAG.tar.xz
mv aur-mirror-$AUR_TAG /hinance-docker/aur
rm aur-mirror-$AUR_TAG.tar.xz
