#!/bin/sh

set -e

APP='hinance-controller'
APPW='hinance-worker'

. /usr/share/$APP/repo/config.sh
. /etc/$APP/config.sh

export AWS_KEY
export AWS_SECRET
export APP_VERSION

IP=$(python2 -B /usr/share/$APP/repo/$APP/docker/cloud.py -l info --run)

echo "Instance IP is: $IP"

chmod 600 /var/lib/$APP/key.pem

run_remote() {
    set -e
    ssh -i /var/lib/$APP/key.pem ubuntu@$IP "$@";
    set +e
}

wait_remote() {
    while run-remote ls 2>&1|grep \
        "Connection closed\|Connection reset\|Connection refused" \
    >/dev/null ; do
        echo "Connecting to the instance."
        sleep 1
    done
}

wait_remote

scp -i /var/lib/$APP/key.pem \
    /usr/share/$APP/repo/$APP/docker/setup_remote.sh \
    ubuntu@$IP:~/

run_remote ./setup_remote.sh $APP_VERSION
python2 -B /usr/share/$APP/repo/$APP/docker/cloud.py -l info --stop
python2 -B /usr/share/$APP/repo/$APP/docker/cloud.py -l info --run >/dev/null
wait_remote
run_remote sudo /usr/share/$APPW/repo/$APPW/run.sh
python2 -B /usr/share/$APP/repo/$APP/docker/cloud.py -l info --delete

