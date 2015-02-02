#!/bin/sh

set -e

pacman -S --noconfirm --needed base base-devel cabal-install firefox \
                               git mupdf xorg-server-xvfb
