#!/bin/sh

set -e

CBLREPO=$HOME/.cabal/bin/cblrepo

# habs
cabal update
cabal install cblrepo-0.13
cd /hinance-docker/habs
$CBLREPO sync
$CBLREPO add pretty-show,1.6.8 regex-tdfa,1.2.0
$CBLREPO pkgbuild haskell-lexer pretty-show mtl text parsec \
                  regex-base regex-tdfa
rm -rf $HOME/.{cabal,ghc}
sudo pacman -Rs cabal-install

# ghc
cd /hinance-docker/habs/ghc
makepkg -sc --noconfirm
sudo pacman -U --noconfirm ghc-7.8.3-1-x86_64.pkg.tar.gz

# haskell-haskell-lexer
cd /hinance/docker/habs/haskell-haskell-lexer
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-haskell-lexer-1.0-4-x86_64.pkg.tar.gz

# haskell-pretty-show
cd /hinance/docker/habs/haskell-pretty-show
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-pretty-show-1.6.8-2-x86_64.pkg.tar.gz

# haskell-mtl
cd /hinance/docker/habs/haskell-mtl
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-mtl-2.1.3.1-4-x86_64.pkg.tar.xz

# haskell-text
cd /hinance/docker/habs/haskell-text
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-text-1.1.1.3-2-x86_64.pkg.tar.xz

# haskell-parsec
cd /hinance/docker/habs/haskell-parsec
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-parsec-3.1.7-1-x86_64.pkg.tar.xz

# haskell-regex-base
cd /hinance/docker/habs/haskell-regex-base
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-regex-base-0.93.2-57-x86_64.pkg.tar.xz

# haskell-regex-tdfa
cd /hinance/docker/habs/haskell-regex-tdfa
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-regex-tdfa-1.2.0-63-x86_64.pkg.tar.gz

# python2-elementtidy
cd /hinance-docker/aur/python2-elementtidy
makepkg -sc --noconfirm
pacman -U --noconfirm python2-elementtidy-1.0-1-x86_64.pkg.tar.xz

# python2-html2text
cd /hinance-docker/aur/python2-html2text
makepkg -sc --noconfirm
pacman -U --noconfirm python2-html2text-2014.9.25-2-any.pkg.tar.xz

# python2-selenium
# TODO: remove this patch when the package is updated
cd /hinance-docker/aur/python2-selenium
patch PKGBUILD /hinance-docker/setup/python2-selenium/PKGBUILD.patch
makepkg -sc --noconfirm
pacman -U --noconfirm python2-selenium-2.43.0-1-x86_64.pkg.tar.xz

# weboob-git
cd /hinance-docker/aur/weboob-git
patch PKGBUILD /hinance-docker/setup/weboob-git/PKGBUILD.patch
makepkg -sc --noconfirm
pacman -U --noconfirm weboob-git-2402b546-1-x86_64.pkg.tar.xz

# leiningen
cd /hinance-docker/aur/leiningen
makepkg -sc --noconfirm
pacman -U --noconfirm leiningen-1\:2.5.0-1-any.pkg.tar.xz

# hinance
# TODO: use aur package
cd /hinance-docker/setup/hinance
makepkg -sc --noconfirm
pacman -U --noconfirm hinance-0.0.0dev-1-any.pkg.tar.xz

#TODO: run hinance once to pull all lein dependencies
