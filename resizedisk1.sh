#!/usr/bin/sh

#
# resizedisk1.sh
#
# Written by John Westerman, March 25, 2021 10:53
#
# What this script does is takes a resized base CentOS disk,
# removes the partition for the large volume and repartitions
# it using the entire disk space. This is an "expand" of a hard
# disk.
#
# This is done first and the system is rebooted.
# see resizedisk2.sh for the next step.
#

fdisk /dev/sda <<EOF
p
d
2
n
p
2


t
2
8e
w
q
EOF

reboot
