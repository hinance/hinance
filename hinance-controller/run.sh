#!/bin/sh

set -e

APP="hinance-controller"

. /usr/share/$APP/repo/config.sh

IMAGE="olegus8/$APP:$APP_VERSION"

if docker ps|grep $APP >/dev/null ; then
    echo "Stopping old $APP container."
    docker stop $APP >/dev/null
fi

if docker ps -a|grep $APP >/dev/null ; then
    echo "Removing old $APP container."
    docker rm $APP >/dev/null
fi

if ! docker run --rm $IMAGE pwd >/dev/null 2>&1 ; then
    echo "Building $IMAGE container."
    docker build --rm -t $IMAGE /usr/share/$APP/repo/$APP/docker
fi

docker run \
    -v /etc/localtime:/etc/localtime:ro \
    -v /etc/$APP:/etc/$APP:ro \
    -v /usr/share/$APP/repo:/usr/share/$APP/repo:ro \
    -v /var/lib/$APP:/var/lib/$APP \
    --name $APP -h $APP $IMAGE \
    bash -l /usr/share/$APP/repo/$APP/docker/run.sh
