#!/bin/sh

set -e

APP='hinance-controller'
APPW='hinance-worker'

. /usr/share/$APP/repo/config.sh
. /etc/$APP/config.sh

export AWS_KEY
export AWS_SECRET
export APP_VERSION

get_ip() { IP=$(cat /var/lib/$APP/ip.txt) ; }

run_remote() { get_ip ; ssh -i /var/lib/$APP/key.pem ubuntu@$IP "$@" ; }

wait_remote() {
    while run_remote ls 2>&1|grep \
        "Connection closed\|Connection reset\|Connection refused" \
    >/dev/null ; do
        echo "Connecting to the instance."
        sleep 1
    done
}

cloud_cmd() {
    rm -rf /var/lib/$APP/success
    python2 -B /usr/share/$APP/repo/$APP/docker/cloud.py -l info "$@" &
    local PID=$!
    for run in {1..20} ; do
        if [ ! -e /proc/$PID ] ; then break ; fi
        sleep 10
    done
    if [ -e /var/lib/$APP/success ] ; then break ; fi
    set +e ; kill -9 $PID ; set -e
}

while true ; do
    while true ; do cloud_cmd --delete ; done
    cloud_cmd --run
done

get_ip
echo "Instance IP is: $IP"
chmod 600 /var/lib/$APP/key.pem

wait_remote

scp -i /var/lib/$APP/key.pem \
    /usr/share/$APP/repo/$APP/docker/setup_remote.sh \
    ubuntu@$IP:~/

run_remote ./setup_remote.sh $APP_VERSION

while true ; do cloud_cmd --stop ; done
while true ; do cloud_cmd --run ; done

wait_remote
run_remote sudo /usr/share/$APPW/repo/$APPW/run.sh

while true ; do cloud_cmd --delete ; done
