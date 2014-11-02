#!/bin/sh

set -e

APP='hinance-worker'
APP_VERSION=$1

sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install git docker.io

sudo mkdir /etc/$APP
sudo git clone -b "$APP_VERSION" \
    https://github.com/olegus8/hinance.git /usr/share/$APP/repo
