#!/bin/sh

set -e

APP='hinance-controller'

log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S") run]: $@"
}

sleep_for() {
  log "Sleeping for $1 seconds."
  sleep $1
}

sleep_for 
while true ; do
  DATAFILE="data-$(date +"%Y-%m-%d_%H-%M").json"
  log "Fetching $DATAFILE"
  while true ; do
    log "Restarting fetcher."
    set +e; kill $PID; set -e
    /usr/share/$APP/repo/$APP/docker/fetch.sh $DATAFILE
    PID=$!
    for i in {0..10} ; do
      if [ -e /var/lib/$APP/$DATAFILE ] ; then break ; fi
      sleep_for 60
    done
    if [ -e /var/lib/$APP/$DATAFILE ] ; then break ; fi
  done
  sleep_for 10
  #sleep_for 86400
done
