#!/bin/sh

set -e

# Arch Haskell snapshot of 2014-11-11.
HABS_TAG=6dc782392572bc3f118b7af1f81fd8a7dc395e33

# habs
git clone https://github.com/archhaskell/habs /hinance-docker/habs
cd /hinance-docker/habs
git checkout $HABS_TAG
CBLREPO=${HOME}/.cabal/bin/cblrepo
$CBLREPO sync
$CBLREPO pkgbuild $($CBLREPO build base|tail -n +2)
