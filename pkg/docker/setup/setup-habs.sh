#!/bin/sh

set -e

cabal update
cabal install cblrepo-0.13
cd /hinance-docker/habs
CBLREPO=${HOME}/.cabal/bin/cblrepo
$CBLREPO sync
$CBLREPO pkgbuild $($CBLREPO build base|tail -n +2)
