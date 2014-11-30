#!/bin/sh

set -e

# minutes
FETCH_TIMEOUT=60 # Instances are billed per whole hours.
FETCH_PERIOD=$((24*60))

APP='hinance-controller'

. /usr/share/$APP/repo/config.sh
. /etc/$APP/config.sh

cat /usr/share/$APP/repo/$APP/docker/nginx.conf.template \
  | sed -e "s/REPORT_HOST/$REPORT_HOST/" > /etc/nginx/nginx.conf

patch /etc/ssl/openssl.cnf /usr/share/$APP/repo/$APP/docker/openssl.cnf.patch

mkdir -p /var/log/nginx
mkdir -p /var/tmp/$APP

if [ ! -e /var/tmp/$APP/access.htpasswd ] ; then
    htpasswd -bc /var/tmp/$APP/access.htpasswd hinance "$PASSPHRASE"
fi

if [[ ! -e /var/tmp/$APP/https.crt || ! -e /var/tmp/$APP/https.key ]] ; then
    openssl req -x509 -newkey rsa:2048 -days 9999 -nodes \
        -keyout /var/tmp/$APP/https.key -out /var/tmp/$APP/https.crt
    CRT=$(sed -n -e '2,25p' /var/tmp/$APP/https.crt)
    base64 -d <<< "$CRT" | md5sum > /var/lib/$APP/https.md5
    base64 -d <<< "$CRT" | sha1sum > /var/lib/$APP/https.sha1
fi

nginx

while true ; do
  DATAFILE="data-$(date +"%Y-%m-%d_%H-%M").tar.gz.gpg"
  echo "Fetching $DATAFILE"
  while true ; do
    /usr/share/$APP/repo/$APP/docker/fetch.sh $DATAFILE &
    PID=$!
    COUNT=$FETCH_TIMEOUT
    while (( COUNT > 0 )) ; do
      if [ ! -e /proc/$PID ] ; then break ; fi
      echo "Will restart fetcher in $COUNT minutes."
      COUNT=$((COUNT-1))
      sleep 60
    done
    if [ -e /var/lib/$APP/$DATAFILE ] ; then break ; fi
    echo "Restarting fetcher."
    set +e; kill -9 $PID; set -e
  done
  echo "Next fetch is due in $FETCH_PERIOD minutes."
  sleep $((FETCH_PERIOD*60))
done
