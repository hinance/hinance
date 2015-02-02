#!/bin/sh

set -e

pacman -S --noconfirm --needed ghc
cabal update
cabal install -j 50 cblrepo-0.13
