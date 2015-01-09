#!/bin/sh

set -e

APP="hinance-worker"

mkdir -p /tmp/$APP/chew.src

echo -e "module Hinance.Bank.Data where\nimport Hinance.Bank.Type\n\
import Hinance.Currency\nbanksraw = []" > /tmp/$APP/chew.src/bank_data.hs
echo -e "module Hinance.Shop.Data where\nimport Hinance.Shop.Type\n\
import Hinance.Currency\nshopsraw = []" > /tmp/$APP/chew.src/shop_data.hs

set +e
cat /{etc,var/lib}/$APP/banks_*.hs.part >> /tmp/$APP/chew.src/bank_data.hs
cat /{etc,var/lib}/$APP/shops_*.hs.part >> /tmp/$APP/chew.src/shop_data.hs
set -e

cp -t /tmp/$APP/chew.src /etc/$APP/*.hs \
  /usr/share/$APP/repo/$APP/docker/*.{hs,clj{,s}}
ghc -O -XFlexibleInstances -o /tmp/$APP/chew /tmp/$APP/chew.src/*.hs

/tmp/$APP/chew > /var/lib/$APP/chew.hs

cd /tmp/$APP/chew.src
lein cljsbuild once

mkdir -p /var/lib/$APP/report
cd /var/lib/$APP/report
echo '<!DOCTYPE html><html lang="en"><head><title>chew</title>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
      </head><body><pre>' > index.html
echo -e "-- Generated on $(date)\n" >> index.html
cat /var/lib/$APP/chew.hs >> index.html
echo '</pre></body></html>' >> index.html
