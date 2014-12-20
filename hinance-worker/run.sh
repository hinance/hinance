#!/bin/sh

set -e

APP="hinance-worker"

. /usr/share/$APP/repo/config.sh
. /etc/$APP/config.sh

IMAGE="olegus8/$APP:$APP_VERSION"

if ! docker run --rm $IMAGE uname -a ; then
  echo "Building $IMAGE container."
  docker build --rm -t $IMAGE /usr/share/$APP/repo/$APP/docker
fi

chmod 600 /etc/$APP/backends
mkdir -p /var/{lib,log}/$APP

for FILE in $(ls /etc/$APP/*.tar.gz.gpg); do
  gpg2 --passphrase "$PASSPHRASE" --batch -d $FILE 2>/dev/null | tar -xz
done

run() {
  if docker ps|grep $APP >/dev/null ; then
    echo "Stopping old $APP container."
    docker stop $APP >/dev/null
  fi
  if docker ps -a|grep $APP >/dev/null ; then
    echo "Removing old $APP container."
    docker rm $APP >/dev/null
  fi
  docker run \
    -v /etc/localtime:/etc/localtime:ro \
    -v /etc/$APP:/etc/$APP:ro \
    -v /usr/share/$APP/repo:/usr/share/$APP/repo:ro \
    -v /var/lib/$APP:/var/lib/$APP \
    --name $APP -h $APP $IMAGE \
    bash -l /usr/share/$APP/repo/$APP/docker/run.sh "$@" &
  RUN_PID=$!
}

echo "Scraping started."

echo "Obtaining list of backends."
run python2 -c "from weboob.core import Weboob; \
  open('/var/lib/$APP/backends.txt','w').write( \
    ' '.join(sorted(Weboob().load_backends().keys())))"
wait $RUN_PID

echo "Backends to scrape: $(cat /var/lib/$APP/backends.txt)"

DATE=$(date +"%Y_%m_%d_%H_%M")
for BACKEND in $(cat /var/lib/$APP/backends.txt) ; do
  while [ ! -e /var/lib/$APP/${BACKEND}_banks.hs ] ; do
    echo "Scraping backend $BACKEND"
    run proxychains python2 -B /usr/share/$APP/repo/$APP/docker/scrape.py \
      -addv -b $BACKEND --logging-file /dev/null \
      -o /var/lib/$APP/$BACKEND \
      -H /var/lib/$APP/${BACKEND}_tick
    while [ -e /proc/$RUN_PID ] ; do
      # Typically it takes less than a minute to scrape some new data.
      rm -rf /var/lib/$APP/${BACKEND}_tick
      for TICK in {3..1} ; do
        sleep 30
        if [ ! -e /proc/$RUN_PID ] ; then break ; fi
        if [ -e /var/lib/$APP/${BACKEND}_tick ] ; then break ; fi
        echo "Waiting for scraper heartbeat: $TICK"
      done
      if [ ! -e /var/lib/$APP/${BACKEND}_tick ] ; then
        echo "Scraper is stuck."
        set +e; docker stop $APP >/dev/null; wait $RUN_PID; set -e
      fi
    done
    mkdir -p /var/log/$APP/$BACKEND
    DIR=$(mktemp -d /var/log/$APP/$BACKEND/run.XXX)
    docker cp hinance-worker:/tmp $DIR
    echo "Logs saved to $DIR"
  done
  cat /var/lib/$APP/${BACKEND}_banks.hs >> /var/lib/$APP/banks_${DATE}.hs.part
  cat /var/lib/$APP/${BACKEND}_shops.hs >> /var/lib/$APP/shops_${DATE}.hs.part
done

echo "Chewing."
run /usr/share/$APP/repo/$APP/docker/chew.sh
wait $RUN_PID

cd /var/lib/$APP
tar -czf data.tar.gz banks_*.hs.part shops_*.hs.part chew.hs
cd /var/lib/$APP/report
tar -czf /var/lib/$APP/report.tar.gz *
cd /var/log/$APP
tar -czf /var/lib/$APP/log.tar.gz *

for FILE in $(ls /var/lib/$APP/{data,log}.tar.gz) ; do
  gpg2 --passphrase "$PASSPHRASE" --batch -c $FILE >/dev/null 2>&1
done

echo "Scraping finished."
