#!/bin/sh

set -e

APP="hinance-worker"

ln -s /usr/bin/python{2,}
export PATH=$PATH:/usr/share/$APP/weboob/scripts
export PYTHONPATH=$PYTHONPATH:/usr/share/$APP/weboob
export WEBOOB_BACKENDS=/etc/$APP/backends
export DISPLAY=:0

weboob-config
patch $HOME/.config/weboob/sources.list \
    /usr/share/$APP/repo/$APP/docker/sources.list.patch
weboob-config update

Xvfb &

boobank -adv -f json_line -O /var/lib/$APP/data.json ls
