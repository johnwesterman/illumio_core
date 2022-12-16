#!/usr/bin/env sh

#
# setup.sh
#
# Written by John Westerman, March 25, 2021 10:45
#   version 2.0
#     updated: Thursday December 15, 2022 17:55
#     serial: 20221215175600
#
# The purpose of this script is to install a minimal snc0
# version of a PCE on a bare bones CentOS image.
#
# If an IP address is not provided this script takes no other parameters.
#
# This script assumes you have provided the following:
# 1. An single RPM for PCE Core has been provided
# 2. An single RPM for PCE UI has been provided
# 3. A single VEN Bundle file has been provided if it is desired to be installed.
# 4. A VEN compatibility matrix
# 5. This script
#
# Before starting make sure you have enough resources. For the latest code base of 22.5
# and setting up a single node cluster I use 6 CPUs and 8GB RAM at a minimum. Disk space
# is also important but not as important as CPU and RAM. If you use 1GB RAM an 2 CPUs
# do not expect this to work well. If you do not want the PCE to complain about
# resources for build 22.5 you will need a 80GB HDD, 18GB RAM and 6 CPUs.

if [ "$1" == "" ]; then
	ipaddr=$(hostname -I)
	echo "No IP address provided so I am using the host IP: " $ipaddr
else
	ipaddr=$1
	echo "The IP address for this installation will be " $ipaddr
fi

HOSTNAME="pce.test.local"
hostnamectl set-hostname $HOSTNAME
DEMOPASSWORD="Illumio123"
HTTP_FRONT=8443
HTTP_BACK=8444

dnf update -y
dnf install -y net-tools bzip2

# set up time services and disable the firewall
# systemctl start ntpd.service; systemctl enable ntpd.service
systemctl start chronyd; systemctl enable chronyd
systemctl stop firewalld; systemctl disable firewalld

# I prefer not to have SELINUX enforcing in my testing environment.
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

echo "
* soft core unlimited
* hard core unlimited
* hard nproc 65535
* soft nproc 65535
* hard nofile 65535
* soft nofile 65535
" >> /etc/security/limits.conf

echo "
* hard nproc 65535
* soft nproc 65535
" >> /etc/security/limits.d/20-nproc.conf

echo "
fs.file-max = 2000000
net.core.somaxconn = 16384
kernel.shmmax = 60000000
vm.overcommit_memory = 1
">> /etc/sysctl.conf

echo "The host name for this installation will be: " $HOSTNAME
echo "
NETWORKING=yes
HOSTNAME=`hostname`
">> /etc/sysconfig/network

echo "
$ipaddr `hostname`
">> /etc/hosts

# Install the RPMs provided.
# Limit this to 1 PCE and 1 UI or be more specific as necessary.
# rpm -ivh *.rpm
dnf -y install /tmp/*.rpm

# I use these aliases to shorten my command line work.
echo "
alias ctl='sudo -u ilo-pce /opt/illumio-pce/illumio-pce-ctl'
alias ctldb='sudo -u ilo-pce /opt/illumio-pce/illumio-pce-db-management'
alias ctlenv='sudo -u ilo-pce /opt/illumio-pce/illumio-pce-env'
" > /root/pcealiases
cat /root/pcealiases >> /root/.bash_profile

# Batch mode setup of the cert and environemnt
/opt/illumio-pce/illumio-pce-env setup --generate-cert -b \
		pce_fqdn="$HOSTNAME" \
		service_discovery_fqdn="$HOSTNAME" \
		node_type=snc0 \
		email_address=jwesterman@illumio.com \
		front_end_https_port=$HTTP_FRONT \
		front_end_event_service_port=$HTTP_BACK \
		front_end_management_https_port=$HTTP_FRONT \
		syslog_event_export_format=json \
		expose_user_invitation_link=true \
		login_banner="You are the force. Be you."

source /root/pcealiases

# set up the base PCE
echo "Setting up the PCE now."
ctl start --runlevel 1; ctl status -svw
ctldb setup; ctl set-runlevel 5; ctl status -svw

# set up a demo user
echo "Setting up a demo user."
sudo -u ilo-pce ILO_PASSWORD=Illumio123  /opt/illumio-pce/illumio-pce-db-management create-domain --user-name demo@illumio.com --full-name "Demo User" --org-name "Illumio"

# set up the VEN repo
echo "Setting up the VEN repo."
if [ -e /tmp/illumio-ven-bundle-* ]; then
	chmod 777 /tmp/illumio-ven-bundle-*
	ctl ven-software-install /tmp/illumio-ven-bundle-* --compatibility-matrix `ls /tmp/illumio-release-compatibility-*.tar.bz2` --orgs all --default --no-prompt
else
	echo "No bundle file was provided. Skipping..."
fi

# Insert the logrotate script so the disk doesn't grow indefinitely
cp /opt/illumio-pce/templates/pce-logrotate.conf /etc/logrotate.d/

echo "In case you need it:"
echo "My IP address is: " $ipaddr
echo "My host name is: " `hostname`
