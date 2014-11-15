#!/bin/sh

set -e

APP="hinance-worker"

mkdir -p /var/lib/$APP/chew.src
cp -t /var/lib/$APP/chew.src /etc/$APP/*.hs /var/lib/$APP/{bank,shop}_data.hs \
  /usr/share/$APP/repo/$APP/docker/*.hs
ghc -XFlexibleInstances -o /var/lib/$APP/chew /var/lib/$APP/chew.src/*.hs

/var/lib/$APP/chew > /var/lib/$APP/chew.hs
