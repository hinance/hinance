#!/bin/sh

set -e

pacman -S --noconfirm --needed ghc
cabal update
cabal install --jobs=50 cblrepo-0.13
