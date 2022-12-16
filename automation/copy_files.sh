#!/bin/sh

#
# copy_files.sh
#
# Written by John Westerman, March 25, 2021 10:50
#
# This copies the base files for PCE install to a CentOS host while
# setting up seamless ssh login in the process.
#

if [ "$1" == "" ]; then
	echo "Missing IP address target. Gimme an IP address."
	exit 0
fi

ssh-copy-id root@$1
scp *.rpm setup.sh resize* root@$1:/tmp
scp *.bz2 root@$1:/tmp
