#!/bin/sh

set -e

# minutes
FETCH_TIMEOUT=30
FETCH_PERIOD=1440

APP='hinance-controller'

while true ; do
  DATAFILE="data-$(date +"%Y-%m-%d_%H-%M").tar.gz"
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
