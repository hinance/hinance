#!/bin/sh

set -e

APP="hinance-worker"
VERSION="0.0.0-dev"

if docker ps|grep $APP >/dev/null ; then
    echo "Stopping old $APP container."
    docker stop $APP >/dev/null
fi

if docker ps -a|grep $APP >/dev/null ; then
    echo "Removing old $APP container."
    docker rm $APP >/dev/null
fi

if ! docker run --rm $APP:$VERSION pwd >/dev/null 2>&1 ; then
    echo "Building $APP:$VERSION container."
    docker build --rm -t $APP:$VERSION /usr/share/$APP/repo/$APP/docker
fi

docker run \
    -v /etc/localtime:/etc/localtime:ro \
    -v /etc/$APP:/etc/$APP:ro \
    -v /usr/share/$APP/repo:/usr/share/$APP/repo:ro \
    --name $APP -h $APP $APP:$VERSION \
    bash -l /usr/share/$APP/repo/$APP/docker/run.sh
