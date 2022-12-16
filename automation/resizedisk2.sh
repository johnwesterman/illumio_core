#!/usr/bin/sh

#
# resizedisk2.sh
#
# Written by John Westerman, March 25, 2021 10:53
#
# What this script does is takes a resized base CentOS disk,
# expands the file system to grow to the full available disk size.
#
# This is the second part of the expand process.
# see resizedisk1.sh for the first, requisite, step.
#

pvresize /dev/sda2
lvresize /dev/mapper/centos-root /dev/sda2
xfs_growfs /dev/centos/root
df -h
