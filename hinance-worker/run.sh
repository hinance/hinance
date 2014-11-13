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
    bash -l /usr/share/$APP/repo/$APP/docker/run.sh "$@"
}

echo "Scraping started."

echo "Obtaining list of backends."
run python2 -c "from weboob.core import Weboob; \
  open('/var/lib/$APP/backends.txt','w').write( \
    ' '.join(sorted(Weboob().load_backends().keys())))"

echo "Backends to scrape: $(cat /var/lib/$APP/backends.txt)"

echo "module HinanceBanks where\nimport HinanceTypes\nbanks = []\n" \
  > /var/lib/$APP/banks.hs
echo "module HinanceShops where\nimport HinanceTypes\nshops = []\n" \
  > /var/lib/$APP/shops.hs

for BACKEND in $(cat /var/lib/$APP/backends.txt) ; do
  while [ ! -e /var/lib/$APP/${BACKEND}_banks.hs ] ; do
    echo "Scraping backend $BACKEND"
    set +e
    run python2 -B /usr/share/$APP/repo/$APP/docker/scrape.py -addv \
      -b $BACKEND --logging-file /dev/null \
      -o /var/lib/$APP/$BACKEND
    set -e
    mkdir -p /var/log/$APP/$BACKEND
    DIR=$(mktemp -d /var/log/$APP/$BACKEND/run.XXX)
    docker cp hinance-worker:/tmp $DIR
    echo "Logs saved to $DIR"
  done
  cat /var/lib/$APP/${BACKEND}_banks.hs >> /var/lib/$APP/banks.hs
  cat /var/lib/$APP/${BACKEND}_shops.hs >> /var/lib/$APP/shops.hs
done

cd /var/lib/$APP
tar -czf data.tar.gz banks.hs shops.hs
cd /var/log/$APP
tar -czf /var/lib/$APP/log.tar.gz *

for FILE in $(ls /var/lib/$APP/{data,log}.tar.gz) ; do
  gpg2 --passphrase "$PASSPHRASE" --batch -c $FILE >/dev/null 2>&1
done

echo "Scraping finished."
