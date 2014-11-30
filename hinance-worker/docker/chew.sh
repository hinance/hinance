#!/bin/sh

set -e

APP="hinance-worker"

mkdir -p /tmp/$APP/chew.src
cp -t /tmp/$APP/chew.src /etc/$APP/*.hs /var/lib/$APP/{bank,shop}_data.hs \
  /usr/share/$APP/repo/$APP/docker/*.hs
ghc -O -XFlexibleInstances -o /tmp/$APP/chew /tmp/$APP/chew.src/*.hs

/tmp/$APP/chew > /var/lib/$APP/chew.hs

mkdir -p /var/lib/$APP/report
cd /var/lib/$APP/report
echo '<!DOCTYPE html><html lang="en"><head><title>chew</title>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
      </head><body><pre>' > index.html
echo -e "-- Generated on $(date)\n" >> index.html
cat /var/lib/$APP/chew.hs >> index.html
echo '</pre></body></html>' >> index.html
