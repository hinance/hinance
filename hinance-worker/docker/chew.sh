#!/bin/sh

set -e

APP="hinance-worker"

. /usr/share/$APP/repo/config.sh
. /etc/$APP/config.sh

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION

mkdir -p /tmp/$APP/chew.src
cp -t /tmp/$APP/chew.src /etc/$APP/*.hs /var/lib/$APP/{bank,shop}_data.hs \
  /usr/share/$APP/repo/$APP/docker/*.hs
ghc -O -XFlexibleInstances -o /tmp/$APP/chew /tmp/$APP/chew.src/*.hs

/tmp/$APP/chew > /var/lib/$APP/chew.hs

echo '<!DOCTYPE html><html lang="en"><head><title>chew</title>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
      </head><body><pre>' > /var/lib/$APP/chew.html
echo -e "-- Generated on $(date)\n" >> /var/lib/$APP/chew.html
cat /var/lib/$APP/chew.hs >> /var/lib/$APP/chew.html
echo '</pre></body></html>' >> /var/lib/$APP/chew.html

echo "Updating the S3 bucket $S3_BUCKET"
aws s3 mb s3://$S3_BUCKET
aws s3 website s3://$S3_BUCKET --index-document index.html
aws s3 cp --acl public-read /var/lib/$APP/chew.html \
  s3://$S3_BUCKET/index.html
