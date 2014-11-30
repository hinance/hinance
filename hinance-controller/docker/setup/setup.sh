#!/bin/sh

set -e

APP="hinance-controller"

# Arch Rollback Machine date.
ARM_YEAR=2014
ARM_MONTH=10
ARM_DAY=05

echo "Server = http://rollback.adminempire.com/$ARM_YEAR/$ARM_MONTH/$ARM_DAY/\$arch/\$repo" > /etc/pacman.d/mirrorlist
pacman -Syyuu --noconfirm

pacman -S --noconfirm apache nginx patch python2-pip
paccache -rk0

pip2 install awscli==1.5.4
