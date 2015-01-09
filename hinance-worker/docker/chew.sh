#!/bin/sh

set -e

APP="hinance-worker"

mkdir -p /tmp/$APP/chew.src/src-hs
cp -t /tmp/$APP/chew.src/src-hs /etc/$APP/*.hs \
  /usr/share/$APP/repo/$APP/docker/src-hs/*
cp -rt /tmp/$APP/chew.src /usr/share/$APP/repo/$APP/docker/{*.clj,src-cljs}

echo -e "module Hinance.Bank.Data where\nimport Hinance.Bank.Type\n\
import Hinance.Currency\nbanksraw = []" >/tmp/$APP/chew.src/src-hs/bank_data.hs
echo -e "module Hinance.Shop.Data where\nimport Hinance.Shop.Type\n\
import Hinance.Currency\nshopsraw = []" >/tmp/$APP/chew.src/src-hs/shop_data.hs

set +e
cat /{etc,var/lib}/$APP/banks_*.hs.part>>/tmp/$APP/chew.src/src-hs/bank_data.hs
cat /{etc,var/lib}/$APP/shops_*.hs.part>>/tmp/$APP/chew.src/src-hs/shop_data.hs
set -e

ghc -O -XFlexibleInstances -o /tmp/$APP/chew /tmp/$APP/chew.src/src-hs/*.hs

echo 'Chewing.'
/tmp/$APP/chew > /var/lib/$APP/chew.hs

cd /tmp/$APP/chew.src
lein cljsbuild once

mkdir -p /var/lib/$APP/report
cp -t /var/lib/$APP/report /tmp/$APP/chew.src/chew.js \
  /usr/share/$APP/repo/$APP/docker/chew.html
