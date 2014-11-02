#!/bin/sh

set -e

SLEEP=10

APP='hinance-controller'
APPW='hinance-worker'

. /usr/share/$APP/repo/config.sh
. /etc/$APP/config.sh

STAMP="$APP-$APP_VERSION"

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION

function log {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")]: $@"
}

get_stack_info() {
  set +e
  INFO=$(aws cloudformation describe-stacks --stack-name $STAMP 2>/dev/null)
  set -e
}

get_stack_status() {
  get_stack_info
  if [ "$INFO" != "" ] ; then
    SSTATUS=$(python2 -c 'import json,sys; print json.loads(sys.stdin.read()) \
                          ["Stacks"][0]["StackStatus"]' <<< "$INFO")
  else
    SSTATUS=
  fi
}

get_stack_output() {
  get_stack_info
  OUTPUT=$(python2 -c \
    "import sys,json; print dict((x['OutputKey'], x['OutputValue']) \
       for x in json.loads(sys.stdin.read())['Stacks'][0]['Outputs'] \
     )['$1']" <<< "$INFO")
}

get_instance_status() {
  get_stack_output myInstanceId
  ISTATUS=$(aws ec2 describe-instance-status --instance-id $OUTPUT|python2 -c\
            'import json,sys; print json.loads(sys.stdin.read()) \
             ["InstanceStatuses"][0]["InstanceState"]["Name"]')
}

run_remote() {
  get_stack_output myInstanceIp
  ssh -i /var/lib/$APP/$STAMP.pem ec2-user@$OUTPUT "$@"
}

wait_remote() {
  while run_remote ls 2>&1|grep \
    "Connection closed\|Connection reset\|Connection refused" \
  >/dev/null ; do
    echo "Connecting to the instance."
    sleep $SLEEP
  done
}

reboot_remote() {
  get_stack_output myInstanceId
  aws ec2 reboot-instances --instance-ids $OUTPUT
  get_instance_status
  while [ "$ISTATUS" != "running" ] ; do
    echo "Rebooting instance. Current status: $ISTATUS"
    sleep $SLEEP
    get_instance_status
  done
  wait_remote
}

delete_stack() {
  aws cloudformation delete-stack --stack-name $STAMP
  while true ; do
    get_stack_status
    log "Deleting stack. Current status: $SSTATUS"
    if [ "$SSTATUS" == "" ] ; then break ; fi 
    sleep $SLEEP
  done
}

create_stack() {
  while true ; do
    aws cloudformation create-stack --stack-name $STAMP \
      --template-body file:///usr/share/$APP/repo/$APP/docker/cloud.json \
      --parameters ParameterKey=appVersion,ParameterValue="$APP_VERSION" \
                   ParameterKey=keyName,ParameterValue="$STAMP" \
      >/dev/null
    while true ; do
      get_stack_status
      log "Creating stack. Current status: $SSTATUS"
      if [[ "$SSTATUS" == 'CREATE_COMPLETE' \
         || "$SSTATUS" == 'ROLLBACK_COMPLETE' ]] ;
      then
        break
      fi
      sleep $SLEEP
    done
    if [ "$SSTATUS" == 'CREATE_COMPLETE' ] ; then break ; fi
    delete_stack
  done
  wait_remote
}

aws ec2 delete-key-pair --key-name $STAMP
aws ec2 create-key-pair --key-name $STAMP | python2 -c \
  'import json,sys; print json.loads(sys.stdin.read())["KeyMaterial"]' \
  > /var/lib/$APP/$STAMP.pem
chmod 600 /var/lib/$APP/$STAMP.pem

delete_stack
create_stack
run_remote "set -e; sudo yum -y update; sudo yum -y install git docker; \
            sudo mkdir -p /etc/$APPW; sudo git clone -b \"$APP_VERSION\" \
            https://github.com/olegus8/hinance.git /usr/share/$APPW/repo"
reboot_remote
run_remote "set -e; sudo service docker start; \
            sudo /usr/share/$APPW/repo/$APPW/run.sh"

delete_stack
aws ec2 delete-key-pair --key-name $STAMP
