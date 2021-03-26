#!/usr/bin/sh

#
# setup.sh
#
# Written by John Westerman, March 25, 2021 10:45
#
# The purpose of this script is to install a minimal snc0
# version of a PCE on a bare bones CentOS image.
#
# This script takes no parameters.
#
# This script assumes:
# 1. An single RPM for PCE Core has been provided
# 2. An single RPM for PCE UI has been provided
# 3. A single VEN Bundle file has been provided if it is desired to be installed.

if [ "$1" == "" ]; then
	ipaddr=$(hostname -I)
	echo "No IP address provided so I am using the host IP: " $ipaddr
else
	ipaddr=$1
fi

echo "The IP address I shall use is " $ipaddr
HOSTNAME="pce.test.local"
hostnamectl set-hostname $HOSTNAME
DEMOPASSWORD="Illumio123"
HTTP_FRONT=8443
HTTP_BACK=8444

yum update -y
yum install -y net-tools bzip2 ntp

# set up NTP server and disable the firewall
systemctl start ntpd.service; systemctl enable ntpd.service
systemctl stop firewalld; systemctl disable firewalld

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
fs.file-max          = 2000000
net.core.somaxconn   = 16384
kernel.shmmax        = 60000000
vm.overcommit_memory = 1
">> /etc/sysctl.conf

echo "The host name I am using is: " $HOSTNAME
echo "
NETWORKING=yes
HOSTNAME=`hostname`
">> /etc/sysconfig/network

echo "
$ipaddr `hostname`
">> /etc/hosts

# Install the RPMs provided.
# Limit this to 1 PCE and 1 UI or be more specific as necessary.
rpm -ivh *.rpm

# I use these aliases to shorten my command line work.
echo "
alias ctl='sudo -u ilo-pce /opt/illumio-pce/illumio-pce-ctl'
alias ctldb='sudo -u ilo-pce /opt/illumio-pce/illumio-pce-db-management'
alias ctlenv='sudo -u ilo-pce /opt/illumio-pce/illumio-pce-env'
" > /root/pcealiases

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
		login_banner="You are the force."

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
	ctl ven-software-install /tmp/illumio-ven-bundle-* --orgs all --default --no-prompt
else
	echo "No bundle file was provided. Skipping..."
fi

# Insert the logrotate script so the disk doesn't grow indefinitely
cp /opt/illumio-pce/templates/pce-logrotate.conf /etc/logrotate.d/

echo "In case you need it:"
echo "My IP address is: " $ipaddr
echo "My host name is: " `hostname`