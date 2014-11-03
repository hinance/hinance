#!/bin/sh

set -e

# minutes
FETCH_TIMEOUT=30
FETCH_PERIOD=1

APP='hinance-controller'

log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S") run]: $@"
}

while true ; do
  DATAFILE="data-$(date +"%Y-%m-%d_%H-%M").json"
  log "Fetching $DATAFILE"
  while true ; do
    /usr/share/$APP/repo/$APP/docker/fetch.sh $DATAFILE &
    PID=$!
    COUNT=$FETCH_TIMEOUT
    while (( COUNT > 0 )) ; do
      if [ ! -e /proc/$PID ] ; then break ; fi
      log "Will restart fetcher in $COUNT minutes."
      COUNT=$((COUNT-1))
      sleep 60
    done
    if [ -e /var/lib/$APP/$DATAFILE ] ; then break ; fi
    log "Restarting fetcher."
    set +e; kill -9 $PID; set -e
  done
  log "Next fetch is due in $FETCH_PERIOD minutes."
  sleep $((FETCH_PERIOD*60))
done
