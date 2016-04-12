#!/bin/bash

set -e

. /hinance-docker/setup/share.sh

LANG=en_US.UTF-8
LC_COLLATE=en_US.UTF-8
LC_TIME=en_US.UTF-8

CBLREPO=$HOME/.cabal/bin/cblrepo

# cblrepo
cd /hinance-docker/cblrepo
cabal update
cabal install --jobs=36 --only-dependencies
cabal configure --user
cabal build --jobs=36
cabal install --jobs=36

# habs
cd /hinance-docker/habs
$CBLREPO update
$CBLREPO add pretty-show,1.6.8.2 regex-tdfa,1.2.1 old-locale,1.0.0.7
$CBLREPO pkgbuild haskell-lexer pretty-show mtl text parsec \
                  regex-base regex-tdfa old-locale
rm -rf $HOME/.{cabal,ghc}
sudo pacman -Rs --noconfirm cabal-install

# ghc
cd /hinance-docker/habs/ghc
patch -cp1 < /hinance-docker/setup/ghc/the.patch
makepkg -sc --noconfirm
sudo pacman -U --noconfirm ghc-7.10.2-2-x86_64.pkg.tar.xz

# haskell-old-locale
cd /hinance-docker/habs/haskell-old-locale
echo '16c16
< depends=("ghc=7.10.2-1")
---
> depends=("ghc=7.10.2-2")' | patch PKGBUILD
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-old-locale-1.0.0.7_1-1-x86_64.pkg.tar.xz

# haskell-haskell-lexer
cd /hinance-docker/habs/haskell-haskell-lexer
echo '16c16
< depends=("ghc=7.10.2-1")
---
> depends=("ghc=7.10.2-2")' | patch PKGBUILD
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-haskell-lexer-1.0_0-78-x86_64.pkg.tar.xz

# haskell-pretty-show
cd /hinance-docker/habs/haskell-pretty-show
echo '16c16
< depends=("ghc=7.10.2-1"
---
> depends=("ghc=7.10.2-2"' | patch PKGBUILD
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-pretty-show-1.6.8.2_1-1-x86_64.pkg.tar.xz

# haskell-mtl
cd /hinance-docker/habs/haskell-mtl
echo '16c16
< depends=("ghc=7.10.2-1")
---
> depends=("ghc=7.10.2-2")' | patch PKGBUILD
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-mtl-2.2.1_1-78-x86_64.pkg.tar.xz

# haskell-text
cd /hinance-docker/habs/haskell-text
echo '16c16
< depends=("ghc=7.10.2-1")
---
> depends=("ghc=7.10.2-2")' | patch PKGBUILD
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-text-1.2.1.3_1-2-x86_64.pkg.tar.xz

# haskell-parsec
cd /hinance-docker/habs/haskell-parsec
echo '16,18c16,18
< depends=("ghc=7.10.2-1"
<          "haskell-mtl=2.2.1_0-78"
<          "haskell-text=1.2.1.3_0-2")
---
> depends=("ghc=7.10.2-2"
>          "haskell-mtl=2.2.1_1-78"
>          "haskell-text=1.2.1.3_1-2")' | patch PKGBUILD
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-parsec-3.1.9_0-83-x86_64.pkg.tar.xz

# haskell-regex-base
cd /hinance-docker/habs/haskell-regex-base
echo '16,17c16,17
< depends=("ghc=7.10.2-1"
<          "haskell-mtl=2.2.1_0-78")
---
> depends=("ghc=7.10.2-2"
>          "haskell-mtl=2.2.1_1-78")' | patch PKGBUILD
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-regex-base-0.93.2_0-78-x86_64.pkg.tar.xz

# haskell-regex-tdfa
cd /hinance-docker/habs/haskell-regex-tdfa
echo '16,17c16,17
< depends=("ghc=7.10.2-1"
<          "haskell-mtl=2.2.1_0-78"
---
> depends=("ghc=7.10.2-2"
>          "haskell-mtl=2.2.1_1-78"' | patch PKGBUILD
makepkg -sc --noconfirm
sudo pacman -U --noconfirm haskell-regex-tdfa-1.2.1_0-1-x86_64.pkg.tar.xz

# python2-elementtidy
fetch-aur python2-elementtidy
makepkg -sc --noconfirm
sudo pacman -U --noconfirm python2-elementtidy-1.0-3-x86_64.pkg.tar.xz

# python2-html2text
fetch-aur python2-html2text
makepkg -sc --noconfirm
sudo pacman -U --noconfirm python2-html2text-2015.4.14-1-any.pkg.tar.xz

# python-pysqlite
fetch-aur python-pysqlite
makepkg -sc --noconfirm
sudo pacman -U --noconfirm python2-pysqlite-2.6.3-5-any.pkg.tar.xz

# v8
fetch-aur v8
git apply /hinance-docker/setup/v8/the.patch
makepkg -sc --noconfirm
sudo pacman -U --noconfirm v8-3.30.33.16-2-x86_64.pkg.tar.xz

# weboob-git
fetch-aur weboob-git
git apply /hinance-docker/setup/weboob-git/the.patch
makepkg -sc --noconfirm
sudo pacman -U --noconfirm weboob-git-6fdb0946-1-x86_64.pkg.tar.xz
weboob-config update

# hinance
git clone https://github.com/hinance/hinance /hinance-docker/hinance.git
cd /hinance-docker/hinance.git
git checkout 1.1.0draft
cd /hinance-docker/hinance.git/pkg/archlinux
makepkg -sc --noconfirm
sudo pacman -U --noconfirm hinance-1.1.0draft-1-any.pkg.tar.xz
