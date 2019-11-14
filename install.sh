#!/bin/bash
clear

# Check if we are root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root." 1>&2
   exit 1
fi

cp unifi-update.sh /root/unifi-update.sh