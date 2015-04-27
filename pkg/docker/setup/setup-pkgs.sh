#!/bin/bash

set -e

. /hinance-docker/setup/share.sh

CBLREPO=$HOME/.cabal/bin/cblrepo

# cblrepo
cd /hinance-docker/cblrepo
patch -p4 < /hinance-docker/habs/patches/cblrepo.source
cabal update
cabal install --only-dependencies
cabal configure --user
cabal build
cabal install

# habs
cd /hinance-docker/habs
$CBLREPO sync
$CBLREPO add pretty-show,1.6.8.2 regex-tdfa,1.2.0
$CBLREPO pkgbuild haskell-lexer pretty-show mtl text parsec \
                  regex-base regex-tdfa
rm -rf $HOME/.{cabal,ghc}
sudo pacman -Rs --noconfirm cabal-install

# ghc
cd /hinance-docker/habs/ghc
makepkg -sc --noconfirm
sudo pacman -U --noconfirm ghc-7.8.4-1-x86_64.pkg.tar.xz

# haskell-haskell-lexer
cd /hinance-docker/habs/haskell-haskell-lexer
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-haskell-lexer-1.0-5-x86_64.pkg.tar.xz

# haskell-pretty-show
cd /hinance-docker/habs/haskell-pretty-show
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-pretty-show-1.6.8.2-1-x86_64.pkg.tar.xz

# haskell-mtl
cd /hinance-docker/habs/haskell-mtl
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-mtl-2.1.3.1-5-x86_64.pkg.tar.xz

# haskell-text
cd /hinance-docker/habs/haskell-text
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-text-1.2.0.4-1-x86_64.pkg.tar.xz

# haskell-parsec
cd /hinance-docker/habs/haskell-parsec
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-parsec-3.1.8-1-x86_64.pkg.tar.xz

# haskell-regex-base
cd /hinance-docker/habs/haskell-regex-base
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-regex-base-0.93.2-58-x86_64.pkg.tar.xz

# haskell-regex-tdfa
cd /hinance-docker/habs/haskell-regex-tdfa
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-regex-tdfa-1.2.0-1-x86_64.pkg.tar.xz

# python2-elementtidy
fetch-aur /py python2-elementtidy
makepkg -sc --noconfirm
sudo pacman -U --noconfirm python2-elementtidy-1.0-2-x86_64.pkg.tar.xz

# python2-html2text
fetch-aur /py python2-html2text
makepkg -sc --noconfirm
sudo pacman -U --noconfirm python2-html2text-2014.12.24-1-any.pkg.tar.xz

# python-pysqlite
fetch-aur /py python-pysqlite
makepkg -sc --noconfirm
sudo pacman -U --noconfirm python2-pysqlite-2.6.3-4-x86_64.pkg.tar.xz

# weboob-git
fetch-aur /we weboob-git
patch PKGBUILD /hinance-docker/setup/weboob-git/PKGBUILD.patch
makepkg -sc --noconfirm
sudo pacman -U --noconfirm weboob-git-5d2152ac-1-x86_64.pkg.tar.xz

# hinance
# TODO: use aur package
cd /hinance-docker/setup/hinance
makepkg -sc --noconfirm
sudo pacman -U --noconfirm hinance-0.0.0dev-1-any.pkg.tar.xz

cd /hinance-docker/setup
hinance
