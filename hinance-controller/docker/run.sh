#!/bin/sh

set -e

APP='hinance-controller'

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
    STATUS=$(python2 -c 'import json,sys; print json.loads(sys.stdin.read()) \
                         ["Stacks"][0]["StackStatus"]' <<< "$INFO")
  else
    STATUS=
  fi
}

delete_stack() {
  aws cloudformation delete-stack --stack-name $STAMP
  while true ; do
    get_stack_status
    log "Deleting stack. Current status: $STATUS"
    if [ "$STATUS" == "" ] ; then break ; fi 
    sleep 10
  done
}

create_stack() {
  while true ; do
    aws cloudformation create-stack --stack-name $STAMP \
      --template-body file:///usr/share/$APP/repo/$APP/docker/cloud.json \
      --parameters ParameterKey=AppVersion,ParameterValue="$APP_VERSION" \
      >/dev/null
    while true ; do
      get_stack_status
      log "Creating stack. Current status: $STATUS"
      if [[ "$STATUS" == 'CREATE_COMPLETE' \
         || "$STATUS" == 'ROLLBACK_COMPLETE' ]] ;
      then
        break
      fi
      sleep 10
    done
    if [ "$STATUS" == 'CREATE_COMPLETE' ] ; then break ; fi
    delete_stack
  done
}

aws ec2 delete-key-pair --key-name $STAMP
aws ec2 create-key-pair --key-name $STAMP | python2 -c \
  'import json,sys; print json.loads(sys.stdin.read())["KeyMaterial"]' \
  > /var/lib/$APP/$STAMP.pem

delete_stack
create_stack

get_stack_info
log "Info: $INFO"

delete_stack
aws ec2 delete-key-pair --key-name $STAMP

get_stack_info
log "Info: $INFO"
