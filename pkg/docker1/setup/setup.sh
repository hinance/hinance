#!/bin/sh

set -e

# Arch Rollback Machine date.
ARM_YEAR=2014
ARM_MONTH=11
ARM_DAY=11

echo "Server = " \
     "http://seblu.net/a/arm/$ARM_YEAR/$ARM_MONTH/$ARM_DAY/\$repo/os/\$arch" \
     > /etc/pacman.d/mirrorlist
pacman -Syyuu --noconfirm
