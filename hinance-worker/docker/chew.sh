#!/bin/sh

set -e

APP="hinance-worker"

mkdir -p /tmp/$APP/chew.src
cp -t /tmp/$APP/chew.src /etc/$APP/*.hs /var/lib/$APP/{bank,shop}_data.hs \
  /usr/share/$APP/repo/$APP/docker/*.hs
ghc -XFlexibleInstances -o /tmp/$APP/chew /tmp/$APP/chew.src/*.hs

/tmp/$APP/chew > /var/lib/$APP/chew.hs
