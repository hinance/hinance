#!/bin/sh

set -e

APP="hinance-worker"

. /usr/share/$APP/repo/config.sh

IMAGE="olegus8/$APP:$APP_VERSION"

if ! docker run --rm $IMAGE uname -a ; then
  echo "Building $IMAGE container."
  docker build --rm -t $IMAGE /usr/share/$APP/repo/$APP/docker
fi

chmod 600 /etc/$APP/backends
mkdir -p /var/lib/$APP

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
  from weboob.capabilities.bank import CapBank; \
  open('/var/lib/$APP/backends.txt','w').write( \
    ' '.join(Weboob().load_backends(CapBank).keys()))"

echo "Backends to scrape: $(cat /var/lib/$APP/backends.txt)"

for BACKEND in $(cat /var/lib/$APP/backends.txt) ; do
  while [ ! -e /var/lib/$APP/$BACKEND.json ] ; do
    echo "Scraping backend $BACKEND"
    set +e
    run python2 -B /usr/share/$APP/repo/$APP/docker/scrape.py $BACKEND \
      /var/lib/$APP/$BACKEND.json
    set -e
  done
done

cd /var/lib/$APP
tar -czf data.tar.gz *.json

echo "Scraping finished."
