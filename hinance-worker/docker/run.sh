#!/bin/sh

set -e

APP="hinance-worker"

. /usr/share/$APP/repo/config.sh
. /etc/$APP/config.sh

if [ "$SOCKS_SSH_HOST" != "" ] ; then
  echo "Connecting to proxy ${SOCKS_SSH_HOST}."
  mkdir -p $HOME/.ssh
  echo "$SOCKS_SSH_HOST" "$SOCKS_SSH_HOST_PUBKEY" > $HOME/.ssh/known_hosts
  echo "$SOCKS_SSH_USER_PVTKEY" > /var/lib/$APP/socks.pem
  chmod 600 /var/lib/$APP/socks.pem
  ssh -fND 51080 -i /var/lib/$APP/socks.pem \
    ${SOCKS_SSH_USER}@${SOCKS_SSH_HOST}
fi

ln -s /usr/bin/python{2,}
export PATH=$PATH:/usr/share/$APP/weboob/scripts
export PYTHONPATH=$PYTHONPATH:/usr/share/$APP/weboob
export WEBOOB_BACKENDS=/etc/$APP/backends
export DISPLAY=:0

patch /etc/proxychains.conf \
  /usr/share/$APP/repo/$APP/docker/proxychains.conf.patch

weboob-config >/dev/null 2>&1
patch $HOME/.config/weboob/sources.list \
  /usr/share/$APP/repo/$APP/docker/sources.list.patch
weboob-config update

Xvfb &

"$@"
